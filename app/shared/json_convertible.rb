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
      def to_json(options = {})
        to_object_dictionary.to_json(options)
      end

      # @ignore_instance_variables: optional to provide a list of
      #   variables to attributes to ignore
      #   @example
      #
      #     ignore_instance_variables: [:@project, :@something_else]
      #
      def to_object_dictionary(ignore_instance_variables: [])
        object_hash = {}
        instance_variables.each do |var|
          next if ignore_instance_variables.include?(var)
          # If we encounter with a `var` which value is an `Array`, we should iterate
          # over its value and use its own `to_object_dictionary`.
          if instance_variable_get(var).kind_of?(Array)
            object_array = []
            instance_variable_get(var).each do |obj|
              # If the `Array` type does not include the JSONConvertible mixin, don't
              # call `to_object_dictionary` on the elements, since the method does not exist
              if obj.class.include?(JSONConvertible)
                object_array << obj.to_object_dictionary
              else
                object_array << obj
              end
            end
            # In this step we have all the objects, lastly we need the key of the array.
            var_name, = _to_object_dictionary(var)
            object_hash[var_name] = object_array
          else
            var_name, instance_variable_value = _to_object_dictionary(var)
            object_hash[var_name] = instance_variable_value
          end
        end
        return object_hash
      end

      protected

      def _to_object_dictionary(var)
        # For a given object variable we check if it includes some custom value mapping to JSON.
        if self.class.attribute_name_to_json_proc_map.key?(var)
          instance_variable_value = self.class.attribute_name_to_json_proc_map[var].call(instance_variable_get(var))
        else
          instance_variable_value = instance_variable_get(var)
        end
        # For a given object variable we check if it includes some custom property mapping to JSON
        if self.class.attribute_key_name_map.key?(var)
          var_name = self.class.attribute_key_name_map[var]
        else
          var_name = var.to_s[1..-1]
        end
        return var_name, instance_variable_value
      end
    end

    # add these as class methods
    module ClassMethods
      def from_json!(json_object)
        instance, json_object = _initialize_using!(json_object)
        json_object.each do |var, val|
          # If we encounter with a value that is represented by an array, iterate over it.
          if val.kind_of?(Array)
            # For each of the objects in the array, we call the protected method to build the object array.
            array_property = []
            array_name = nil
            val.each do |array_val|
              array_name, this_instance = _from_json!(var, array_val, is_iterable: true)
              array_property << this_instance
            end
            if array_name.nil?
              if attribute_key_name_map.key(var)
                array_name = attribute_key_name_map.key(var).to_sym
              else
                array_name = "@#{var}".to_sym
              end
            end
            instance.instance_variable_set(array_name, array_property)
          else
            var_name, var_value = _from_json!(var, val)
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

      # class method
      # This method is intended to be overridden by any
      # class that implements `JSONConvertible` and need
      # to provide a custom mapping for a enumerable property
      # in the JSON.
      #
      # @param enumerable_property_name [Any] the property name of the object.
      # @param current_json_object [Hash] the hash object of `enumerable_property_name` for a given iteration step.
      #
      #   @example
      #
      #     def map_enumerable_type(enumerable_property_name: nil, current_json_object: nil)
      #       if enumerable_property_name == :@job_triggers
      #         JobTrigger needs a factory method that reads `json[:type]` and instantiates the proper type
      #         return  FastlaneCI::JobTrigger.create(json: current_json_object)
      #       end
      #     end
      # @return [Any] object in the array by the given `property_name` and `json_object`.
      def map_enumerable_type(enumerable_property_name: nil, current_json_object: nil)
        return nil
      end

      protected

      def _from_json!(var, val, is_iterable: false)
        # TODO: attribute_key_name_map doesn't seem to be used anywhere in the code base
        if attribute_key_name_map.key(var)
          var_name = attribute_key_name_map.key(var).to_sym
        else
          var_name = "@#{var}".to_sym
        end

        if json_to_attribute_name_proc_map.key?(var_name)
          var_value = json_to_attribute_name_proc_map[var_name].call(val)
        else
          var_value = val
        end

        if attribute_to_type_map.key?(var_name)
          if attribute_to_type_map[var_name].include?(FastlaneCI::JSONConvertible)
            # classes that include `JSONConvertible` take precedence over custom mapping.
            var_value = attribute_to_type_map[var_name].from_json!(val)
          else
            raise TypeError, "#{var_name} does not implement `FastlaneCI::JSONConvertible`"
          end
        elsif is_iterable
          # This is only intended for array properties, it passes the final variable name and a single object of
          # the variable array. Expects to return and object.
          var_value = map_enumerable_type(enumerable_property_name: var_name, current_json_object: val)
        end

        return var_name, var_value
      end

      def _initialize_using!(json_object)
        instance = allocate
        required_init_params = instance.method(:initialize).parameters
                                       .select { |arg| arg[0] == :keyreq }
                                       .map(&:last)
        unless (required_init_params - json_object.keys).empty?
          raise TypeError, "Required initialization parameters not found in the object: #{json_object}"
        end
        init_params_hash = json_object.select { |key, _value| required_init_params.include?(key) }
        if instance.method(:initialize).parameters.empty?
          instance.send(:initialize)
        else
          instance.send(:initialize, init_params_hash)
        end
        clean_json_object = json_object.reject { |key| required_init_params.include?(key) }
        return instance, clean_json_object
      end
    end
  end
end
