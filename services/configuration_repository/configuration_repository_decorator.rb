require_relative "../services"
require_relative "./configuration_repository_service"

module FastlaneCI
  # This module acts as a decorator to be added to any method that potentially will make changes
  # into the ci-config repository directory.
  #
  #     @example
  #       class Klass
  #         extends FastlaneCI::ConfigurationRepositoryUpdater
  #
  #         def my_custom_function
  #           method_that_reads_and_writes_files_of_ci_config_repo
  #         end
  #         pull_before(:my_custom_function)
  #         commit_after(:my_custom_function, file_path: "path/to/file.json")
  #       end
  #
  # In this way every method that potentially can make changes over the ci-config repo is
  # delayed until the ci-config repo is updated from remote, as it is our source of truth.
  module ConfigurationRepositoryUpdater
    prepend FastlaneCI::Logging
    # This decorator method is responsible of pulling and committing-pushing changes from the ci-config repo.
    class << self
      def pull_operation_mutex
        @pull_operation_mutex ||= Mutex.new
      end

      def commit_operation_mutex
        @commit_operation_mutex ||= Mutex.new
      end
    end

    def pull_before(func_name)
      new_name_for_old_function = "#{func_name}_old".to_sym
      alias_method(new_name_for_old_function, func_name)
      define_method(func_name) do |*args|
        # Here we use the mutex as a throttling tool. While a pull operation is
        # being made, we drop pulling requests made from other sources and just
        # pipe the original method call without any delay.
        if ConfigurationRepositoryUpdater.pull_operation_mutex.locked?
          send(new_name_for_old_function, *args)
        else
          ConfigurationRepositoryUpdater.pull_operation_mutex.synchronize do
            Services.configuration_repository_service.pull
            send(new_name_for_old_function, *args)
          end
        end
      end
    end

    # TODO: Prototype, to be tested.
    def commit_after(func_name, file_path: nil, config_repo_service: Services.configuration_repository_service)
      raise "config_repo_service must include FastlaneCI::ConfigurationRepositoryService" unless config_repo_service.modules.include?(ConfigurationRepositoryService)
      new_name_for_old_function = "#{func_name}_old".to_sym
      alias_method(new_name_for_old_function, func_name)
      define_method(func_name) do |*args|
        ConfigurationRepositoryUpdater.commit_operation_mutex.synchronize do
          return_value = send(new_name_for_old_function, *args)
          begin
            config_repo_service.commit(file_path: file_path)
            config_repo_service.push
            return return_value
          rescue StandardError => ex
            logger.error(ex)
            # We have to return the value from the original function regardless of possible exceptions raised
            # by the commit or push methods.
            return return_value
          end
        end
      end
    end
  end
end
