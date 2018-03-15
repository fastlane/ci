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

module FastlaneCI
  # Data source that interacts with GitHub
  class GitHubService < CodeHostingService
    include FastlaneCI::Logging

    class << self
      attr_writer :temporary_git_storage

      attr_accessor :temporary_storage_path

      attr_writer :cache

      def cache
        @cache ||= {}
        return @cache
      end

      def client(api_token)
        @client_cache ||= {}
        return @client_cache[api_token] unless @client_cache[api_token].nil?
        client = Octokit::Client.new(access_token: api_token)
        @client_cache[api_token]
        return client
      end

      def temp_path
        temporary_path = File.join(Dir.tmpdir, ".fastlane")
        FileUtils.mkdir_p(temporary_path) unless File.directory?(temporary_path)
        return temporary_path
      end

      def temporary_git_storage
        temp_storage = File.join(Dir.tmpdir, ".tmp")
        @temporary_git_storage ||= temp_storage
        FileUtils.mkdir_p(@temporary_git_storage) unless File.directory?(@temporary_git_storage)
        return @temporary_git_storage
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
      def peek_fastfile_configuration(repo_url: nil, branch: "master", provider_credential: nil, path: self.temp_path, cache: true)
        repo = repo_from_url(repo_url)
        return self.cache[[repo, branch].join("/")] if cache && self.cache && !self.cache[[repo, branch].join("/")].nil? && self.cache[[repo, branch].join("/")].kind_of?(Hash)
        path = File.join(path, repo, branch)
        begin
          git_path = File.join(path, repo.split("/").last)
          # This triggers the check of an existing repo in the given path,
          # we recover from the error making the clone and checkout
          Git.open(git_path)
          fastfile_path = self.fastfile_path(root_path: git_path)
          fastfile = Fastlane::FastfileParser.new(path: fastfile_path)
          fastfile_config = {}
          # TODO: FastfileParser provides a nice and clean tree of the Fastfile given,
          # but there's a specific case when there might be lanes or actions out of
          # a platform scope, in those cases the key is nil. We sanitize that so the user
          # still can select lanes without platform. But this should be done from the
          # FastfileParser side.
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
          self.cache[[repo, branch].join("/")] = fastfile_config
          return fastfile_config
        rescue ArgumentError
          self.setup_auth(
            repo_url: repo_url,
            provider_credential: provider_credential,
            path: path
          )
          self.clone(
            repo_url: repo_url,
            branch: branch,
            provider_credential: provider_credential,
            path: path
          )
          fastfile_config = self.peek_fastfile_configuration(
            repo_url: repo_url,
            branch: branch,
            provider_credential: provider_credential,
            path: path,
            cache: cache
          )
          self.unset_auth
          return fastfile_config
        rescue RuntimeError
          # This is because no Fastfile config was found, so we cannot go further.
          return {}
        end
      end

      # Class method that shallow clones the repo on the target branch.
      # @param [String] repo_url
      # @param [String] branch
      # @param [GithubProviderCredential] provider_credential
      # @return [Git::Base]
      def clone(repo_url: nil, branch: "master", provider_credential: nil, path: self.temp_path)
        repo = self.repo_from_url(repo_url)
        path = File.join(path, repo, branch)
        FileUtils.rm_rf(path) if File.directory?(path)
        FileUtils.mkdir_p(path)
        self.setup_auth(repo_url: repo_url, provider_credential: provider_credential, path: path)
        Git.clone(url_from_repo(repo_url), repo.split("/").last,
                  path: path,
                  recursive: true,
                  depth: 1)
        git = Git.open(File.join(path, repo.split("/").last))
        git.branch(branch).checkout
        return git
      end

      # Class method that finds the directory for the first Fastfile found given a root_path
      # @param [String] root_path
      # @return [String] the path of the Fastfile
      def fastfile_path(root_path: nil)
        fastfiles = Dir[File.join(root_path, "fastlane/Fastfile")]
        fastfiles = Dir[File.join(root_path, "**/fastlane/Fastfile")] if fastfiles.count == 0
        fastfile_path = fastfiles&.first
        return fastfile_path
      end

      # Class method that setups the authentication needed for making git operations.
      # @param [String] repo_url
      # @param [GithubProviderCredential] provider_credential
      # @param [String] path
      def setup_auth(repo_url: nil, provider_credential: nil, path: nil)
        repo = repo_from_url(repo_url)
        git_auth_key = Digest::SHA2.hexdigest(repo_url)
        temporary_storage_path = File.join(self.temporary_git_storage, "git-auth-#{git_auth_key}")
        self.temporary_storage_path = temporary_storage_path
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
        use_credentials_command = "git config --#{scope} credential.helper 'store --file #{self.temporary_storage_path.shellescape}' #{File.join(path, repo.split('/').last)}"

        cmd = TTY::Command.new(printer: :quiet)
        cmd.run(store_credentials_command, input: content)
        cmd.run(use_credentials_command)
        return temporary_storage_path
      end

      # Class method that removes the authentication stored for git operations.
      def unset_auth
        return unless self.temporary_storage_path.kind_of?(String)
        # TODO: Also auto-clean those files from time to time, on server re-launch maybe, or background worker
        FileUtils.rm(self.temporary_storage_path) if File.exist?(self.temporary_storage_path)
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

      # @return [Array<String>]
      def branches(provider_credential: nil, repo_full_name: nil)
        self.client(provider_credential.api_token).branches(repo_full_name).map(&:name)
      end

      def repo_from_url(repo_url)
        return repo_url.sub("https://github.com/", "")
      end

      def url_from_repo(repo)
        return "https://github.com/" + repo unless repo.include?("https://github.com/")
      end
    end

    # The email is actually optional for API access
    # However we ask for the email on login, as we also plan on doing commits for the user
    # and this way we can make sure to configure things properly for git to use the email
    attr_accessor :provider_credential

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
      all_open_pull_requests = client.pull_requests(self.project.repo_config.full_name, state: state)

      # if no specific branch, return all open prs
      return all_open_pull_requests.map(&:html_url) if branches&.count == 0

      pull_requests_on_branch = all_open_pull_requests.select { |pull_request| branches.include?(pull_request.base.ref) }
      # we want only the PRs whose latest commit was to one of the branches passed in
      logger.debug("Returning all open prs from: #{self.project.repo_config.full_name}, branches: #{branches}, pr count: #{pull_requests_on_branch.count}")
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
      numbers = pull_requests_urls.map { |url| URI.parse(url) }.map(&:path).collect { |path| path.split("/").last }
      return numbers.map { |number| commits_sha_from_pull_request(number: number) }.map(&:last)
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
      open_pr_commits = self.last_commit_sha_for_all_open_pull_requests
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
    def branches
      client.branches(self.project.repo_config.full_name).map(&:name)
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
      if state == "missing_fastfile" || state == "ci_problem"
        state = "failure"
      end

      available_states = ["error", "failure", "pending", "success", "ci_problem"]
      raise "Invalid state '#{state}'" unless available_states.include?(state)

      # We auto receive the SLUG, so that the user of this class can pass a full URL also
      repo = self.project.repo_config.full_name

      if description.nil?
        description = "All green" if state == "success"
        description = "Still running" if state == "pending"

        # TODO: what's the difference?
        description = "Build encountered a failure" if state == "failure"
        description = "Build encountered an error " if state == "error"
      end

      # this needs to be synchronous because we're doing it during initialization of our build runner
      state_details = target_url.nil? ? "#{repo}, sha #{sha}" : target_url
      logger.debug("Setting status #{state} -> #{status_context} on #{state_details}")
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
    # @return [#peek_fastfile_configuration]
    def shallow_clone(branch: nil)
      self.class.peek_fastfile_configuration(
        repo_url: self.project.repo_config.git_url,
        branch: branch,
        provider_credential: self.provider_credential,
        path: File.join(self.project.repo_config.containing_path, self.project.id),
        cache: false
      )
    end

    protected

    def repo_from_url(repo_url)
      return repo_url.sub("https://github.com/", "")
    end

    def url_from_repo(repo)
      return "https://github.com/" + repo unless repo.include?("https://github.com/")
    end
  end
end
