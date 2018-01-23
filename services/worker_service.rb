require_relative "../workers/check_for_new_commits_on_github_worker"
require_relative "../shared/logging_module"
require_relative "../shared/models/provider_credential"

module FastlaneCI
  # Manages starting/stopping workers as well as tracking state
  # TODO: figure out when a worker crashes and restart it
  class WorkerService
    include FastlaneCI::Logging

    attr_accessor :resource_workers_dictionary

    def initialize
      self.resource_workers_dictionary = {}
    end

    def resource_workers_dictionary_key(project: nil, user_responsible: nil)
      return "#{project.id}_#{user_responsible.id}"
    end

    def start_worker_for_provider_credential_and_config(project: nil, provider_credential: nil)
      user_responsible = provider_credential.ci_user
      worker_key = resource_workers_dictionary_key(project: project, user_responsible: user_responsible)
      raise "Worker already exists for project: #{project.name}, for user #{user_responsible.email}" unless self.resource_workers_dictionary[worker_key].nil?

      repo_config = project.repo_config
      raise "incompatible repo_config and provider_credential" if provider_credential.type != repo_config.provider_type_needed

      new_worker = nil
      case provider_credential.type
      when FastlaneCI::ProviderCredential::PROVIDER_TYPES[:github]
        new_worker = FastlaneCI::CheckForNewCommitsOnGithubWorker.new(provider_credential: provider_credential, project: project)
      else
        raise "unrecognized provider_type: #{provider_credential.type}"
      end

      self.resource_workers_dictionary[worker_key] = new_worker
      logger.debug("Starting worker for #{project.name}, on behalf of #{user_responsible.email}")
      new_worker.start
    end

    def stop_worker(project: nil, user_responsible: nil)
      worker_key = resource_workers_dictionary_key(project: project, user_responsible: user_responsible)
      worker = self.resource_workers_dictionary[worker_key]

      # worker will die, may take up to `timeout` seconds
      worker.die!

      self.resource_workers_dictionary[worker_key] = nil
    end
  end
end
