require_relative "../workers/check_for_new_commits_on_github_worker"
require_relative "../workers/nightly_build_github_worker"
require_relative "../shared/logging_module"
require_relative "../shared/models/provider_credential"

module FastlaneCI
  # Manages starting/stopping workers as well as tracking state
  # TODO: figure out when a worker crashes and restart it
  class WorkerService
    include FastlaneCI::Logging

    attr_accessor :project_to_workers_dictionary

    def initialize
      self.project_to_workers_dictionary = {}
    end

    def project_to_workers_dictionary_key(project: nil, user_responsible: nil)
      return "#{project.id}_#{user_responsible.id}"
    end

    def start_workers_for_project_and_credential(project: nil, provider_credential: nil)
      user_responsible = provider_credential.ci_user
      workers_key = project_to_workers_dictionary_key(project: project, user_responsible: user_responsible)
      raise "Worker already exists for project: #{project.name}, for user #{user_responsible.email}" unless self.project_to_workers_dictionary[workers_key].nil?

      repo_config = project.repo_config
      raise "incompatible repo_config and provider_credential" if provider_credential.type != repo_config.provider_credential_type_needed

      logger.debug("Starting worker for #{project.project_name}, on behalf of #{user_responsible.email}")
      new_workers = []
      case provider_credential.type
      when FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
        if self.project_has_trigger_type(project: project, trigger_type: FastlaneCI::JobTrigger::TRIGGER_TYPE[:commit])
          new_workers << FastlaneCI::CheckForNewCommitsOnGithubWorker.new(provider_credential: provider_credential, project: project)
        end
        if self.project_has_trigger_type(project: project, trigger_type: FastlaneCI::JobTrigger::TRIGGER_TYPE[:nightly])
          new_workers << FastlaneCI::NightlyBuildGithubWorker.new(provider_credential: provider_credential, project: project)
        end
      else
        raise "unrecognized provider_type: #{provider_credential.type}"
      end

      self.project_to_workers_dictionary[workers_key] = new_workers
    end

    def stop_workers(project: nil, user_responsible: nil)
      workers_key = project_to_workers_dictionary_key(project: project, user_responsible: user_responsible)
      workers = self.project_to_workers_dictionary[workers_key]

      # worker will die, may take up to `timeout` seconds
      workers.each { |worker| worker.die! }

      self.project_to_workers_dictionary[workers_key] = nil
    end

    def num_workers
      self.project_to_workers_dictionary.values.reduce(0) do |sum, workers|
        sum + workers.length
      end
    end

    def project_has_trigger_type(project:nil, trigger_type: nil)
      raise "Need both project and trigger_type" unless project && trigger_type

      project.job_triggers.any? { |trigger| trigger.type == trigger_type }
    end
  end
end
