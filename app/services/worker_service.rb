require_relative "../workers/check_for_new_commits_on_github_worker"
require_relative "../workers/check_for_new_prs_on_github_worker"
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
      @project_to_workers_dictionary = {}
    end

    def project_to_workers_dictionary_key(project: nil, user_responsible: nil)
      logger.debug(
        "Generating a key for project: `#{project.project_name}` (#{project.id}), user: #{user_responsible.email}"
      )
      return "#{project.id}_#{user_responsible.id}"
    end

    def start_workers_for_project_and_credential(project: nil, provider_credential: nil, notification_service:)
      user_responsible = provider_credential.ci_user

      if user_responsible.nil?
        name = project.project_name
        email = provider_credential.email
        raise "Unable to start workers for `#{name}`, no `user_responsible` for given `provider_credential`: #{email}"
      end

      workers_key = project_to_workers_dictionary_key(project: project, user_responsible: user_responsible)

      unless project_to_workers_dictionary[workers_key].nil?
        raise "Worker already exists for project: #{project.project_name}, for user #{user_responsible.email}"
      end

      repo_config = project.repo_config

      if provider_credential.type != repo_config.provider_credential_type_needed
        raise "incompatible repo_config and provider_credential"
      end

      logger.debug("Starting worker for #{project.project_name}, on behalf of #{user_responsible.email}")
      new_workers = []

      case provider_credential.type
      when FastlaneCI::ProviderCredential::PROVIDER_CREDENTIAL_TYPES[:github]
        if project_has_trigger_type?(
          project: project,
          trigger_type: FastlaneCI::JobTrigger::TRIGGER_TYPE[:commit]
        )
          new_workers << FastlaneCI::CheckForNewCommitsOnGithubWorker.new(
            provider_credential: provider_credential,
            project: project,
            notification_service: notification_service
          )
        end

        if project_has_trigger_type?(
          project: project,
          trigger_type: FastlaneCI::JobTrigger::TRIGGER_TYPE[:pull_request]
        )
          new_workers << FastlaneCI::CheckForNewPullRequestsOnGithubWorker.new(
            provider_credential: provider_credential,
            project: project,
            notification_service: notification_service
          )
        end

        if project_has_trigger_type?(project: project, trigger_type: FastlaneCI::JobTrigger::TRIGGER_TYPE[:nightly])
          new_workers << FastlaneCI::NightlyBuildGithubWorker.new(
            provider_credential: provider_credential,
            project: project,
            notification_service: notification_service
          )
        end
      else
        raise "unrecognized provider_type: #{provider_credential.type}"
      end

      project_to_workers_dictionary[workers_key] = new_workers
    end

    def stop_workers(project: nil, user_responsible: nil)
      workers_key = project_to_workers_dictionary_key(project: project, user_responsible: user_responsible)
      workers = project_to_workers_dictionary[workers_key]

      # worker will die, may take up to `timeout` seconds
      workers.each(&:die!)

      project_to_workers_dictionary[workers_key] = nil
    end

    # @return [Integer]
    def num_workers
      return project_to_workers_dictionary.values.reduce(0) do |sum, workers|
        sum + workers.length
      end
    end

    # @return [Boolean]
    def project_has_trigger_type?(project:, trigger_type:)
      return project.job_triggers.any? { |trigger| trigger.type == trigger_type }
    end
  end
end
