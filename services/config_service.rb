require_relative "code_hosting/git_hub_service"
require_relative "config_data_sources/json_project_data_source"
require_relative "../shared/models/github_provider_credential"
require_relative "../shared/logging_module"

module FastlaneCI
  # Provides access to the fastlane.ci configuration, like which projects we're hosting
  class ConfigService
    include FastlaneCI::Logging

    attr_accessor :project_service
    attr_accessor :ci_user
    attr_accessor :active_code_hosting_services # dictionary of active_code_hosting_service_key to CodeHosting

    def initialize(project_service: FastlaneCI::Services.project_service, ci_user: nil)
      self.project_service = project_service
      self.ci_user = ci_user
      self.active_code_hosting_services = {}
    end

    # if the provider_credential is for user B, but the service was initialized using user A,
    # that means user A is doing things on behalf of user B
    def process_on_behalf?(provider_credential: nil)
      return provider_credential.ci_user != self.ci_user
    end

    def active_code_hosting_service_key(provider_credential: nil)
      return "#{provider_credential.provider_name}_#{self.ci_user.id}"
    end

    # Find the active code host for the provider_credential/user combination
    # or instantiate one if none are available
    def code_hosting_service(provider_credential: nil)
      code_hosting_service_key = active_code_hosting_service_key(provider_credential: provider_credential)
      code_hosting_service = self.active_code_hosting_services[code_hosting_service_key]
      return code_hosting_service unless code_hosting_service.nil?

      # TODO: not a big deal right now, but we should have a way of automatically generating the correct
      # CodeHostingService subclass based on the provider_credential type and maybe not have it right here.
      # A Java-style factory might be the right move here.
      case provider_credential.type
      when FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
        code_hosting_service = GitHubService.new(provider_credential: provider_credential)
        active_code_hosting_services[code_hosting_service_key] = code_hosting_service
      else
        raise "Unrecognized provider_credential #{provider_credential.type}"
      end

      return code_hosting_service
    end

    def octokit_projects(provider_credential: nil)
      # Get a list of all the repos `provider` has access to
      logger.debug("Getting code host for #{provider_credential.ci_user.email}, #{provider_credential.type}")
      current_code_hosting_service = self.code_hosting_service(provider_credential: provider_credential)

      # current set of `GitRepoConfig.name`s that `provider_credential` has access to
      current_repo_git_url_set = current_code_hosting_service.repos.map(&:html_url).to_set
      # TODO: we have to improve repo handling, as it seems like we either have to implement
      # proper paging, or we ask for specific repos instead
      # Either way, my account has access to too many repos, so for now, let's just workaround using this
      current_repo_git_url_set << "https://github.com/taquitos/ci-sample-repo"
      current_repo_git_url_set << "https://github.com/fastlane/ci"

      logger.debug("Finding projects we have access to with #{provider_credential.ci_user.email}, #{provider_credential.type}")
      projects = self.project_service.projects.select do |project|
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
