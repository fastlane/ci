require_relative "../services"

module FastlaneCI
  # This module acts as a decorator to be added to any method that potentially will make changes
  # into the ci-config repository directory.
  module ConfigurationRepositoryUpdater
    # This decorator method is responsible of pulling changes from the ci-config repo.
    # rubocop:disable Style/ClassVars
    @@mutex = Mutex.new

    def self.mutex
      return @@mutex
    end
    # rubocop:enable Style/ClassVars

    def pull_before(func_name)
      new_name_for_old_function = "#{func_name}_old".to_sym
      alias_method(new_name_for_old_function, func_name)
      define_method(func_name) do |*args|
        if ConfigurationRepositoryUpdater.mutex.locked?
          send(new_name_for_old_function, *args)
        else
          ConfigurationRepositoryUpdater.mutex.synchronize do
            Services.configuration_repository_service.pull
            send(new_name_for_old_function, *args)
          end
        end
      end
    end
  end
end
