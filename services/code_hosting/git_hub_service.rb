require_relative "code_hosting_service"
require_relative "../../shared/logging_module"
require_relative "../../shared/models/project"
require_relative "../../fastfile-parser/fastfile_parser"

require "set"
require "octokit"
require "git"
require "addressable/uri"
require "tty-command"
require "securerandom"
require "digest"
require "pathname"
require "faraday-http-cache"

module FastlaneCI
  # Data source that interacts with GitHub
  class GitHubService < CodeHostingService
    include FastlaneCI::Logging

    class << self
      include FastlaneCI::Logging

      attr_writer :temporary_git_storage

      attr_writer :temporary_storage_path

      attr_writer :cache

      attr_accessor :git_action_queue

      def cache
        @cache ||= {}
        return @cache
      end

      def clone_mutex
        @mutex ||= Mutex.new
        return @mutex
      end

      protected :cache

      # Loads the octokit cache stack for speed-up calls to github service.
      # As explained in: https://github.com/octokit/octokit.rb#caching
      def load_octokit_cache_stack
        @stack ||= Faraday::RackBuilder.new do |builder|
          builder.use(Faraday::HttpCache, serializer: Marshal, shared_cache: false)
          builder.use(Octokit::Response::RaiseError)
          builder.adapter(Faraday.default_adapter)
        end
        return if Octokit.middleware.handlers.include?(Faraday::HttpCache)
        Octokit.middleware = @stack
      end

      # Client for GitHub related operations
      # @param [String] api_token
      # @return [Octokit::Client]
      def client(api_token)
        load_octokit_cache_stack
        return Octokit::Client.new(access_token: api_token)
      end

      def temp_path(root_path = Dir.tmpdir)
        temporary_path = File.join(root_path, ".fastlane")
        FileUtils.mkdir_p(temporary_path) unless File.directory?(temporary_path)
        return temporary_path
      end

      def temporary_git_storage(root_path = Dir.tmpdir)
        temp_storage = File.join(root_path, ".tmp")
        @temporary_git_storage ||= temp_storage
        FileUtils.mkdir_p(@temporary_git_storage) unless File.directory?(@temporary_git_storage)
        return @temporary_git_storage
      end

      def temporary_storage_path
        @temporary_storage_path ||= {}
        return @temporary_storage_path
      end

      # This method shallow clones the repo using the provider credential and looks for a valid _fastlane_
      # configuration, parses the Fastfile (if found), and returns the lanes in the following way:
      #  {
      #    "no_platform": {
      #      "": {
      #        "description": [
      #
      #        ],
      #        "actions": [
      #          {
      #            "action": "default_platform",
      #            "parameters": "ios"
      #          }
      #        ]
      #      }
      #    },
      #    "ios": {
      #      "test": {
      #        "description": [
      #          "Description of what the lane does"
      #        ],
      #        "actions": [
      #          {
      #            "action": "gym",
      #            "parameters": {
      #              "skip_package_ipa": false,
      #              "clean": true,
      #              "project": "../fastlane-ci-demoapp.xcodeproj",
      #              "scheme": "fastlane-ci-demoapp"
      #            }
      #          }
      #        ],
      #        "private": false
      #      }
      #    }
      #  }
      #
      # @param repo_url [String]
      # @param branch [String]
      # @param path [String]
      # @param provider_credential [GithubProviderCredential]
      # @return [(Fastlane::FastfileParser, Hash<String, Hash>)] the FastlaneParser instance used for the parsing and a hash, being the key the name of the platform (:ios, :android, :no_platform) and the Hash the underlying lane (name, actions).
      def peek_fastfile_configuration(repo_url: nil, branch: nil, provider_credential: nil, path: self.temp_path, cache: true)
        retry_count ||= 0
        repo = repo_from_url(repo_url)
        # We use a "reponame/branch" keyform to store the information in our cache.
        cache_key = [repo, branch].join("/")
        # If cache is allowed for this call, and there's a Hash under the key, use the cache.
        if cache && self.cache[cache_key].kind_of?(Hash)
          return self.cache[cache_key]
        end
        path = File.join(path, repo, branch)
        begin
          git_path = File.join(path, repo.split("/").last)
          # This triggers the check of an existing repo in the given path,
          # we recover from the error making the clone and checkout
          # Raises Argument error when `git_path` is not a valid git path.
          Git.open(git_path)
          fastfile_path = self.fastfile_path(root_path: git_path)
          fastfile = Fastlane::FastfileParser.new(path: fastfile_path)
          fastfile_config = {}
          # TODO: https://github.com/fastlane/fastfile-parser/issues/8
          fastfile.tree.each_key do |key|
            if key.nil?
              fastfile_config[:no_platform] = fastfile.tree[key]
            else
              fastfile_config[key.to_sym] = fastfile.tree[key]
            end
          end
          fastfile_json_path = File.join(path, "fastfile.json")
          FileUtils.touch(fastfile_json_path) unless File.exist?(fastfile_json_path) && !File.zero?(fastfile_json_path)
          File.write(fastfile_json_path, JSON.pretty_generate(fastfile_config))
          self.cache[[repo, branch].join("/")] = fastfile, fastfile_config
          return fastfile, fastfile_config
        rescue ArgumentError
          # Recover from the failed try of opening the existing repo.
          # 1) Clone the repo.
          # 2) Retry the current operation.
          logger.error("Git repository not found at #{git_path}, cloning the repo.")
          self.clone(
            repo_url: repo_url,
            branch: branch,
            provider_credential: provider_credential,
            path: path
          )
          retry if (retry_count += 1) < 5
          raise "Exceeded retry count for #{__method__}."
        rescue RuntimeError
          # This is because no Fastfile config was found, so we cannot go further.
          logger.error("Fastfile configuration was not found on #{repo}" + (branch.nil? ? "" : " and branch #{branch}"))
          return nil, {}
        end
      end

      # Class method that clones a repo.
      # @param [String] repo_url
      # @param [String, nil] branch, the branch to checkout after the clone (Defaults to nil)
      # @param [String, nil] sha, the sha to hard reset from after the clone (Defaults to nil)
      # @param [GithubProviderCredential] provider_credential
      # @param [String, nil] path, root path where the clone will be made
      # @return [Git::Base]
      def clone(repo_url: nil, name: nil, branch: nil, sha: nil, provider_credential: nil, path: nil)
        GitHubService.clone_mutex.synchronize do
          repo = self.repo_from_url(repo_url)

          folder_name = (name.nil? || name.empty?) ? repo.split("/").last : name
          clone_path = (path.nil? || path.empty?) ? self.temp_path : path

          full_clone_path = File.join(clone_path, folder_name)

          FileUtils.rm_rf(full_clone_path) if File.directory?(full_clone_path)
          FileUtils.mkdir_p(clone_path) unless File.directory?(clone_path)

          auth_key = self.setup_auth(repo_url: repo_url, key: (sha || path || "master"), provider_credential: provider_credential, path: clone_path)

          if sha.nil?
            Git.clone(url_from_repo(repo_url), folder_name,
                      path: clone_path,
                      recursive: true,
                      depth: 1)
          else
            Git.clone(url_from_repo(repo_url), folder_name,
                      path: clone_path,
                      recursive: true)
          end

          git = Git.open(full_clone_path)
          git.branch(branch).checkout if sha.nil? && !branch.nil?
          git.reset_hard(git.gcommit(sha)) unless sha.nil?

          self.unset_auth(auth_key)

          return git
        end
      end

      # Class method that finds the directory for the first Fastfile found given a root_path
      # @param [String] root_path
      # @return [String, nil] the path of the Fastfile or nil if no Fastfile found.
      def fastfile_path(root_path: nil)
        fastfiles = Dir[File.join(root_path, "fastlane/Fastfile")]
        fastfiles = Dir[File.join(root_path, "**/fastlane/Fastfile")] if fastfiles.count == 0
        fastfile_path = fastfiles.first
        return fastfile_path
      end

      # Class method that setups the authentication needed for making git operations.
      # @param [String] repo_url
      # @param [GithubProviderCredential] provider_credential
      # @param [String] path
      # @return [String] temporary storage path of the credential-store file.
      def setup_auth(repo_url: nil, key: nil, provider_credential: nil, path: nil)
        repo = repo_from_url(repo_url)
        git_auth_key = Digest::SHA2.hexdigest([repo_url, key].reject { |i| i.nil? || i.empty? }.join)
        temporary_storage_path = File.join(self.temporary_git_storage, "git-auth-#{git_auth_key}")
        self.temporary_storage_path[git_auth_key] = temporary_storage_path
        # More details: https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage

        FileUtils.mkdir_p(path) unless File.directory?(path)

        store_credentials_command = "git credential-store --file #{temporary_storage_path.shellescape} store"
        content = [
          "protocol=https",
          "host=#{provider_credential.remote_host}",
          "username=#{provider_credential.email}",
          "password=#{provider_credential.api_token}",
          ""
        ].join("\n")

        scope = "local"

        unless File.directory?(File.join(path, repo.split("/").last, ".git"))
          # we don't have a git repo yet, we have no choice
          # TODO: check if we find a better way for the initial clone to work without setting system global state
          scope = "global"
        end
        use_credentials_command = "git config --#{scope} credential.helper 'store --file #{self.temporary_storage_path[git_auth_key].shellescape}' #{File.join(path, repo.split('/').last)}"

        cmd = TTY::Command.new(printer: :quiet)
        cmd.run(store_credentials_command, input: content)
        cmd.run(use_credentials_command)
        return git_auth_key
      end

      # Class method that removes the authentication stored for git operations.
      def unset_auth(git_auth_key)
        return unless self.temporary_storage_path[git_auth_key].kind_of?(String)
        # TODO: Also auto-clean those files from time to time, on server re-launch maybe, or background worker
        FileUtils.rm(self.temporary_storage_path[git_auth_key]) if File.exist?(self.temporary_storage_path[git_auth_key])
        self.temporary_storage_path.delete(git_auth_key)
      end

      # @param [GithubProviderCredential] provider_credential
      # @return [Array<GitRepoConfig>]
      def repos(provider_credential: nil)
        self.client(provider_credential.api_token).repos({}, query: { sort: "asc" }).map { |repo| GitRepoConfig.from_octokit_repo!(repo: repo) }
      end

      # Does the client with the associated credentials have access to the specified repo?
      # @return [Bool]
      def access_to_repo?(provider_credential: nil, repo_url: nil)
        self.client(provider_credential.api_token).repository?(repo_from_url(repo_url))
      end

      # @return [Array<String>] names of the branches for the given repo
      def branch_names(provider_credential: nil, repo_full_name: nil)
        self.client(provider_credential.api_token).branches(repo_full_name).map(&:name)
      end

      def repo_from_url(repo_url)
        return repo_url.sub("https://github.com/", "")
      end

      def url_from_repo(repo)
        return repo.include?("https://github.com/") ? repo : "https://github.com/" + repo
      end
    end

    # The email is actually optional for API access
    # However we ask for the email on login, as we also plan on doing commits for the user
    # and this way we can make sure to configure things properly for git to use the email
    attr_accessor :provider_credential

    # @return [Project]
    attr_accessor :project

    def initialize(provider_credential: nil, project: nil)
      self.provider_credential = provider_credential
      raise "Project instance not provided or wrong type parameter" if project.nil? || !project&.kind_of?(Project)
      self.project = project
      @_client = Octokit::Client.new(access_token: provider_credential.api_token)
      Octokit.auto_paginate = true # TODO: just for now, we probably should do smart pagination in the future
    end

    def status_context
      "fastlane.ci: " + @project.id
    end

    def client
      @_client
    end

    # @return [Bool] whether the session is valid or not.
    def session_valid?
      self.client.login.to_s.length > 0
    rescue StandardError
      false
    end

    def username
      self.client.login
    end

    # Returns the urls of the pull requests for a given branch and state.
    # If branches is not provided, all target branches are considered.
    # @param [Array<String>, nil] branches, Either an array of target branches names or nil.
    # @param [String] state, Either open, closed, or all to filter by state. Default: open.
    # @return [String] HTML URL for the given pull request query.
    def pull_requests(branches: nil, state: "open")
      all_pull_requests_with_state = client.pull_requests(self.project.repo_config.full_name, state: state)

      # if no specific branch, return all open prs
      if branches&.empty?
        return all_pull_requests_with_state.map(&:html_url)
      end

      pull_requests_on_branch = all_pull_requests_with_state.select { |pull_request| branches.include?(pull_request.base.ref) }
      # we want only the PRs whose latest commit was to one of the branches passed in
      logger.debug("Returning all prs with state: #{state}, from: #{self.project.repo_config.full_name}, branches: #{branches}, pr count: #{pull_requests_on_branch.count}")
      return pull_requests_on_branch.map(&:html_url)
    end

    # Retrieve all commits' sha from a branch.
    # @param [String] branch
    # @return [Array<String>] List of SHA for a given branch and repo.
    def all_commits_sha_for_branch(branch: nil)
      return client.commits(self.project.repo_config.full_name, branch).map(&:sha)
    end

    # Retrieve the list of sha for a given pull request number.
    # @param [Integer] number, of the pull request.
    # @return [Array<String>] Array of SHA for the given pull request.
    def commits_sha_from_pull_request(number: nil)
      client.pull_commits(self.project.repo_config.full_name, number).map(&:sha)
    end

    # Returns the last sha for every pull request that targets a list of branches (or all if not given) and status (or open if not given)
    # @param [Array<String>, nil] branches, Either an array of target branches names or nil.
    # @param [String] state, Either open, closed, or all to filter by state. Default: open.
    # @return [Array<String>] Array of the last commit SHA for the given repo and state.
    def last_commit_sha_for_pull_requests(branches: nil, state: "open")
      pull_requests_urls = self.pull_requests(branches: branches, state: state)
      numbers = pull_requests_urls.map { |url| URI.parse(url).path.split("/").last }
      return numbers.map { |number| commits_sha_from_pull_request(number: number).last }
    end

    # returns the statused of a given commit sha for a given repo specifically for fastlane.ci
    # TODO: add support for filtering status types, to allow listing of just fastlane.ci status reports
    #       This has to wait for now, until we decide how we separate them for each project, as multiple projects
    #       can run builds for one repo
    def statuses_for_commit_sha(sha: nil)
      all_statuses = client.statuses(self.project.repo_config.full_name, sha)
      only_ci_statuses = all_statuses.select { |status| status.context == self.status_context }
      return only_ci_statuses
    end

    # updates the most current commit to "pending" on all open prs if they don't have a status.
    # returns a list of commits that have been updated to `pending` status
    def update_all_open_prs_without_status_to_pending_status!
      open_pr_commits = self.last_commit_sha_for_pull_requests
      updated_commits = []
      open_pr_commits.each do |sha|
        statuses = self.statuses_for_commit_sha(sha: sha)
        if statuses.count == 0
          self.set_build_status!(sha: sha, state: "pending")
          updated_commits << sha
        end
      end
      return updated_commits
    end

    # @return [Array<String>]
    def branch_names
      return client.branches(self.project.repo_config.full_name).map(&:name)
    end

    # Does the client with the associated credentials have access to the specified repo?
    # @return [Bool]
    def access_to_repo?
      client.repository?(self.project.repo_config.full_name)
    end

    # The `target_url`, `description` and `context` parameters are optional
    # @repo [String] Repo URL as string
    def set_build_status!(sha: nil, state: nil, target_url: nil, description: nil)
      state = state.to_s

      # Available states https://developer.github.com/v3/repos/statuses/
      if state == "missing_fastfile"
        state = "failure"
      end

      available_states = %w{error failure pending success}
      raise "Invalid state '#{state}'" unless available_states.include?(state)

      # We auto receive the SLUG, so that the user of this class can pass a full URL also
      repo = self.project.repo_config.full_name

      if description.nil?
        description = "All green" if state == "success"
        description = "Still running" if state == "pending"

        # TODO: What's the difference?
        description = "Something went wrong" if state == "failure"
        description = "Something went wrong" if state == "error"
      end

      # This needs to be synchronous because we're doing it during initialization of our build runne
      state_details = target_url.nil? ? "#{repo}, sha #{sha}" : target_url
      logger.debug("Setting status #{state} on #{state_details}")
      client.create_status(repo, sha, state, {
        target_url: target_url,
        description: description,
        context: status_context
      })
    rescue StandardError => ex
      logger.error(ex)
      # TODO: how do we handle GitHub errors
      # In this case `create_status` will cause an exception
      # if the user doesn't have write permission for the repo
      raise ex
    end

    # This method shallow clones the project's repo given a branch,
    # returns the Fastfile configuration. Always forces the clone.
    # @param [String] branch
    # @param [String] sha
    # @return [Git::Base]
    def clone(branch: nil, sha: nil)
      logger.debug("Cloning #{project.project_name}, on #{(branch || sha)}") 
      self.class.clone(
        repo_url: self.project.repo_config.git_url,
        branch: branch,
        provider_credential: self.provider_credential,
        sha: sha,
        path: File.join(
          [
            self.project.repo_config.containing_path,
            self.project.id,
            self.project.repo_config.full_name,
            sha
          ].reject { |i| i.nil? || i.empty? }
        )
      )
      return git
    end

    def cleanup(git)
      FileUtils.rm_rf(git.dir) if File.directory?(git.dir) 
    end

    protected

    def repo_from_url(repo_url)
      return self.class.repo_from_url(repo_url)
    end

    def url_from_repo(repo)
      return self.class.url_from_url(repo)
    end
  end
end
