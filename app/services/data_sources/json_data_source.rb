module FastlaneCI
  # define a simple initialization of instances which rely on a JSON file
  module JSONDataSource
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.extend(ClassMethods)
    end

    attr_accessor :json_folder_path

    # add these as class methods
    module ClassMethods
      # Factory method, all JSON-based data sources rely on different
      # JSON files stored in the `json_folder_path` directory.
      #
      # @param [String] json_folder_path
      # @param [any] **params
      # @return [JSONDataSource]
      def create(json_folder_path, **params)
        instance = new
        instance.json_folder_path = json_folder_path
        instance.after_creation(params)
        return instance
      end
    end

    # add this as instance methods
    module InstanceMethods
      # Post-initialization method. This method is optionally
      # overridden by `JSONDataSource`s in order to get injected
      # different parameters that are mandatory for its initialization.
      def after_creation(**params)
      end
    end
  end
end
