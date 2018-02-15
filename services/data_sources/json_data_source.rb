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
      def create(json_folder_path, **params)
        instance = self.new
        instance.json_folder_path = json_folder_path
        instance.after_creation(params)
        return instance
      end
    end

    # add this as instance methods
    module InstanceMethods
      def after_creation(**params)
      end
    end
  end
end
