require "json"

module FastlaneCI
  # make it so any class can be converted to json and back
  module JSONConvertible
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.extend(ClassMethods)
    end

    # add these as instance methods
    module InstanceMethods
      def to_json(options)
        self.to_object_dictionary.to_json(options)
      end

      def to_object_dictionary
        object_hash = {}
        self.instance_variables.each do |var|
          instance_variable_value = self.instance_variable_get(var)
          var_name = var.to_s[1..-1]
          object_hash[var_name] = instance_variable_value
        end
        return object_hash
      end
    end

    # add these as class methods
    module ClassMethods
      def from_json!(json_object)
        instance = self.new
        json_object.each do |var, val|
          instance.instance_variable_set("@#{var}".to_sym, val)
        end
        return instance
      end
    end
  end
end
