require_relative "code_hosting_sources/git_hub_source"
require_relative "config_data_sources/git_config_data_source"
require_relative "../shared/models/github_provider_credential"

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

    # if the provider_credential is for user B, but the service was initialized using user A,
    # that means user A is doing things on behalf of user B
    def process_on_behalf?(provider_credential: nil)
      return provider_credential.ci_user != self.ci_user
    end

    def active_code_hosting_key(provider_credential: nil)
      return "#{provider_credential.provider_name}_#{self.ci_user.id}"
    end

    # Find the active code host for the provider_credential/user combination
    # or instantiate one if none are available
    def code_host(provider_credential: nil)
      code_host_key = active_code_hosting_key(provider_credential: provider_credential)
      code_host = self.active_code_hosts[code_host_key]
      return code_host unless code_host.nil?

      case provider_credential.type
      when FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
        code_host = GitHubSource.new(email: provider_credential.email, personal_access_token: provider_credential.api_token)
        active_code_hosts[code_host_key] = code_host
      else
        raise "Unrecognized provider_credential #{provider_credential.type}"
      end

      return code_host
    end

    def octokit_projects(provider_credential: nil)
      # Get a list of all the repos `provider` has access to
      current_code_host = self.code_host(provider_credential: provider_credential)

      # current set of `GitRepoConfig.name`s that `provider_credential` has access to
      current_repo_git_url_set = current_code_host.repos.map(&:html_url).to_set
      # TODO: we have to improve repo handling, as it seems like we either have to implement
      # proper paging, or we ask for specific repos instead
      # Either way, my account has access to too many repos, so for now, let's just workaround using this
      current_repo_git_url_set << "https://github.com/taquitos/ci-sample-repo"

      projects = self.config_data_source.projects.select do |project|
        current_repo_git_url_set.include?(project.repo_config.git_url)
      end

      # return all projects that are the union of this current user's provider_credential, and the passed in provider_credential
      return projects
    end

    def project(id: nil, provider_credential: nil)
      current_ci_user_projects = self.projects(provider_credential: provider_credential)
      current_project = current_ci_user_projects.select { |project| project.id == id }.first
      return current_project
    end

    def projects(provider_credential: nil)
      if provider_credential.type == FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
        return self.octokit_projects(provider_credential: provider_credential)
      else
        raise "Unrecognized provider_credential #{provider_credential.type}"
      end
    end
  end
end
