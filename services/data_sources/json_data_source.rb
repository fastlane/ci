module FastlaneCI
  # define a simple initialization of instances which rely on a JSON file
  module JSONDataSource
    attr_accessor :json_folder_path

    # add these as class methods
    module ClassMethods
      def create(json_folder_path)
        instance = self.new
        instance.json_folder_path = json_folder_path
        return instance
      end
    end
  end
end
