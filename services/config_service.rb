require_relative "code_hosting_sources/git_hub_source"
require_relative "config_data_sources/git_config_data_source"
require_relative "../shared/models/github_provider"

module FastlaneCI
  class ConfigService
    attr_accessor :config_data_source
    attr_accessor :ci_user
    attr_accessor :active_code_hosts # dictionary of active_code_hosting_key to CodeHosting

    def initialize(config_data_source: FastlaneCI::FastlaneApp::CONFIG_DATA_SOURCE, ci_user: nil)
      self.config_data_source = config_data_source
      self.ci_user = ci_user
      self.active_code_hosts = {}
    end

    # if the provider is for user B, but the service was initialized using user A,
    # that means user A is doing things on behalf of user B
    def process_on_behalf?(provider: nil)
      return provider.ci_user != self.ci_user
    end

    def active_code_hosting_key(provider: nil)
      return "#{provider.provider_name}_#{self.ci_user.id}"
    end

    # Find the active code host for the provider/user combination
    # or instantiate one if none are available
    def code_host(provider: nil)
      code_host_key = active_code_hosting_key(provider: provider)
      code_host = self.active_code_hosts[code_host_key]
      return code_host unless code_host.nil?

      case provider.type
      when FastlaneCI::Provider::PROVIDER_TYPES[:github]
        code_host = GitHubSource.new(email: provider.email, personal_access_token: provider.api_token)
        active_code_hosts[code_host_key] = code_host
      else
        raise "Unrecognized provider #{provider.type}"
      end

      return code_host
    end

    def octokit_projects(provider: nil)
      # Get a list of all the repos `provider` has access to
      current_code_host = self.code_host(provider: provider)

      # current set of `GitRepoConfig.name`s that `provider` has access to
      current_repo_git_url_set = current_code_host.repos.map(&:git_url).to_set

      projects = self.config_data_source.projects.select do |project|
        current_repo_git_url_set.include?(project.repo_config.git_url)
      end

      # return all projects that are the union of this current user's provider, and the passed in provider
      return projects
    end

    def project(id: nil, provider: nil)
      current_ci_user_projects = self.projects(provider: provider)
      current_project = current_ci_user_projects.select { |project| project.id == id }.first
      return current_project
    end

    def projects(provider: nil)
      if provider.type == FastlaneCI::Provider::PROVIDER_TYPES[:github]
        return self.octokit_projects(provider: provider)
      else
        raise "Unrecognized provider #{provider.type}"
      end
    end
  end
end
