require_relative "../services"

module FastlaneCI
  # This module acts as a decorator to be added to any method that potentially will make changes
  # into the ci-config repository directory.
  #
  #     @example
  #       class Klass
  #         extends FastlaneCI::ConfigurationRepositoryUpdater
  #
  #         def my_custom_function
  #           method_that_reads_or_writes_files_of_ci_config_repo
  #         end
  #         pull_before(:my_custom_function)
  #       end
  #
  # In this way every method that potentially can make changes over the ci-config repo is
  # delayed until the ci-config repo is updated from remote, as it is our source of truth.
  module ConfigurationRepositoryUpdater
    # This decorator method is responsible of pulling changes from the ci-config repo.
    class << self
      attr_writer :pull_operation_mutex

      def pull_operation_mutex
        @pull_operation_mutex ||= Mutex.new
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
  end
end
