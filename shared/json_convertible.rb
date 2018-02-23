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

      # @ignore_instance_variables: optional to provide a list of
      #   variables to attributes to ignore
      #   @example
      #
      #     ignore_instance_variables: [:@project, :@something_else]
      #
      def to_object_dictionary(ignore_instance_variables: [])
        object_hash = {}
        self.instance_variables.each do |var|
          next if ignore_instance_variables.include?(var)
          if self.class.attribute_name_to_json_proc_map.key?(var)
            instance_variable_value = self.class.attribute_name_to_json_proc_map[var].call(self.instance_variable_get(var))
          else
            instance_variable_value = self.instance_variable_get(var)
          end
          if self.class.attribute_key_name_map.key?(var)
            var_name = self.class.attribute_key_name_map[var]
          else
            var_name = var.to_s[1..-1]
          end
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
          if self.attribute_key_name_map.key(var)
            var_name = self.attribute_key_name_map.key(var).to_sym
          else
            var_name = "@#{var}".to_sym
          end
          # If we encounter with a value that is represented by an array, iterate over it.
          # TODO: Refactor this in a sepparate protected method to avoid code duplication. DRY.
          if val.kind_of?(Array)
            array_property = []
            val.each do |array_var, array_val|
              this_instance = nil
              if self.attribute_key_name_map.key(array_var)
                array_var_name = self.attribute_key_name_map.key(array_var).to_sym
              else
                array_var_name = "@#{array_var}".to_sym
              end
              if self.json_to_attribute_name_proc_map.key?(array_var_name)
                this_instance = self.json_to_attribute_name_proc_map[array_var_name].call(array_val)
              else
                this_instance = array_val
              end
              if self.attribute_to_type_map.key?(array_var_name)
                if self.attribute_to_type_map[array_var_name].include?(FastlaneCI::JSONConvertible)
                  # classes that include `JSONConvertible` take precedence over custom mapping.
                  this_instance = self.attribute_to_type_map[array_var_name].from_json!(array_val)
                end
              else
                this_instance = self.map_enumerable_type(enumerable_property_name: array_var_name, current_json_object: array_val)
              end
              # What to do if we get `this_instance` nil at this point?
              array_property << this_instance
            end
            instance.instance_variable_set(var_name, array_property)
          else
            if self.json_to_attribute_name_proc_map.key?(var_name)
              var_value = self.json_to_attribute_name_proc_map[var_name].call(val)
            else
              var_value = val
            end
            if self.attribute_to_type_map.key?(var_name)
              if self.attribute_to_type_map[var_name].include?(FastlaneCI::JSONConvertible)
                # classes that include `JSONConvertible` take precedence over custom mapping.
                var_value = self.attribute_to_type_map[var_name].from_json!(val)
              end
            end
            instance.instance_variable_set(var_name, var_value)
          end
        end
        return instance
      end

      # class method
      # This method is intended to be overridden by any
      # class that implements `JSONConvertible` and need
      # to use a custom mapping of the attributes to JSON keys.
      #
      #   @example
      #
      #     def self.attribute_key_name_map
      #       return { :@some_key => "some_key_in_json" }
      #     end
      #
      # @return [Hash] of mapping properties to keys in the JSON
      def attribute_key_name_map
        return {}
      end

      # class method
      # This method is intended to be overridden by any
      # class that implements `JSONConvertible` and need
      # to encode the result of the class attributes in a
      # certain format into the JSON.
      #
      #   @example
      #
      #     def self.attribute_name_to_json_proc_map
      #       timestamp_to_json_proc = proc { |timestamp|
      #         timestamp.strftime('%Q')
      #       }
      #       return { :@timestamp => timestamp_to_json_proc }
      #     end
      #
      # @return [Hash] of properties and procs formatting to JSON
      def attribute_name_to_json_proc_map
        return {}
      end

      # class method
      # This method is intended to be overridden by any
      # class that implements `JSONConvertible` and need
      # to decode the JSON values back to the original types
      # of the class attributes.
      #
      #   @example
      #
      #     def self.json_to_attribute_name_proc_map
      #       json_to_timestamp_proc = proc { |json|
      #         Time.at(json.to_i)
      #       }
      #       return { :@timestamp => json_to_timestamp_proc }
      #     end
      #
      # @return [Hash] of properties and procs formatting from JSON
      def json_to_attribute_name_proc_map
        return {}
      end

      # class method
      # This method is intended to be overridden by any
      # class that implements `JSONConvertible` and need
      # to provide the encoder information about which types
      # are each attribute of the class.
      #
      #   @example
      #
      #
      #     def attribute_to_type_map
      #       return { :@string_attribute => String, :@custom_class_attribute => CustomClass }
      #     end
      #
      # @return [Hash] of properties and their types
      def attribute_to_type_map
        return {}
      end

      # TODO: Document, lazy.
      def self.map_enumerable_type(enumerable_property_name: nil, current_json_object: nil)
        return nil
      end
    end
  end
end
