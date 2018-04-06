require "../../shared/json_convertible"

module FastlaneCI
  # Module used to get the attr_accessor, attr_writer and attr_reader associated methods for
  # a given class, without needing to instanciate it.
  # Credit: https://stackoverflow.com/a/34440466/4161167
  # To use it, just call: YourClass::ATTRS.
  # @return [Array<Symbol>]
  module MethodTracer
    TracePoint.trace(:c_call) do |t|
      if t.method_id.to_s.start_with?("attr_")
        t.self.extend(MethodTracer)

        methods = t.self::ATTRS ||= []
        MethodTracer.send(:define_method, :method_added) { |m| methods << m }
      end
    end

    TracePoint.trace(:c_return) do |t|
      if t.method_id.to_s.start_with?("attr_")
        MethodTracer.send(:remove_method, :method_added)
      end
    end
  end
  # Generic base mixin to create ViewModels from any Model that is JSONConvertible.
  # Used to communicate the backend with the frontend.
  #     @example
  #       class KlassModel
  #         include FastlaneCI::JSONConvertible
  #
  #         attr_accessor :attribute
  #         attr_accessor :other_attribute
  #
  #         def initialize
  #           self.attribute = "hello"
  #           self.other_attribute = "world"
  #         end
  #
  #         def one_method(arg: "Hello", other_arg: "World")
  #           return [arg, other_arg].join(" ")
  #         end
  #       end
  #
  #       class KlassViewModel
  #         include ViewModel
  #         base_models(KlassModel)
  #        end
  #
  #       k = KlassModel.new
  #       viewmodel = KlassViewModel.viewmodel_from!(object: k)
  #       viewmodel # => { "KlassModel" => { "attribute" => "hello", "other_attribute" => "world" } }
  #
  #       class OtherKlassViewModel
  #         include ViewModel
  #         base_models(KlassModel)
  #
  #         def self.included_attributes
  #           return { "KlassModel" => [:@attribute] }
  #         end
  #       end
  #
  #       other_viewmodel = OtherKlassViewModel.viewmodel_from!(k)
  #       other_viewmodel # => { "KlassModel" => { "attribute" => "hello" } }
  #
  #       class OtherKlassModel
  #         include JSONConvertible
  #
  #         attr_accessor :another_attribute
  #         attr_accessor :other_other_attribute
  #
  #         def initialize
  #           self.another_attribute = "foo"
  #           self.other_other_attribute = "bar"
  #         end
  #        end
  #
  #        class KlassViewModel
  #         include ViewModel
  #         base_models(KlassModel, OtherKlassModel)
  #
  #         def self.args_for_method(method)
  #           case method
  #             when :one_method
  #               return { arg: "Foo", other_arg: "Bar" }
  #             end
  #           end
  #         end
  #        end
  #
  #        k = KlassModel.new
  #        o = OtherKlassModel.new
  #        viewmodel = KlassViewModel.viewmodel_from!(k, o)
  #        puts viewmodel # => { "KlassModel"=> { "attribute" => "hello",
  #                                               "other_attribute" => "world",
  #                                               "one_method"=> "Foo Bar"
  #                                             },
  #                              "OtherKlassModel"=> { "another_attribute" => "foo",
  #                                                    "other_other_attribute" => "bar"
  #                                                  }
  #                            }
  #
  module ViewModel
    class << self
      def included(base)
        base.extend(ClassMethods)
      end
    end

    # Add this as Class Methods.
    module ClassMethods
      attr_reader :_base_models

      # Required method to be called overriden by the created ViewModel
      # in order to indicate which class is the Model from which we are creating the ViewModel form.
      # @param [Class] models
      def base_models(*models)
        @_base_models = models
      end

      # An array of the included attributes of the base_model to be included in the ViewModel.
      # @return [Array<Symbol>] the included attributes for the given ViewModel.
      # Defaults to all attr_accessor and attr_reader properties.
      def included_attributes
        attributes_per_model = {}
        _base_models.each do |model|
          attributes_per_model[model.to_s] = model::ATTRS
                                             .reject { |method| method.to_s.end_with?("=") }
                                             .map { |method| "@#{method}".to_sym }
        end
        return attributes_per_model
      end

      # An array of the included methods of the base_model to be included in the ViewModel.
      # @return [Array<Symbol>] the included methods for the given ViewModel. Defaults to all methods.
      def included_methods
        methods_per_model = {}
        _base_models.each do |model|
          methods_per_model[model.to_s] = (model.instance_methods - model::ATTRS - Class.instance_methods)
                                          .map(&:to_sym)
        end
        return methods_per_model
      end

      # Required method
      # It receives each method defined by #included_methods and expects a return type matching the
      # expected method's parameters.
      # @param [Symbol] method
      # @return [Any] parameters for the given `method` name.
      def args_for_method(method)
        not_implemented(__method__)
      end

      # Creates the ViewModel (in shape of a Hash) from a given object of a certain class type.
      # Defined by the base_model method.
      # @params [Any] objects
      # @return [Hash<String, Hash>] object dictionary representation for the ViewModel, where the key
      # is the name of the class and the value is object dictionary representation.
      def viewmodel_from!(*objects)
        viewmodel = {}
        objects.each do |object|
          viewmodel[object.class.to_s] = viewmodel_from_attributes(object).merge(viewmodel_from_methods(object))
        end
        return viewmodel
      end

      private

      def viewmodel_from_methods(object)
        raise "Override base_models(*model) in order to use the ViewModel mixin." if _base_models.nil?
        unless _base_models.any? { |base_model| object.kind_of?(base_model) }
          raise "Incorrect object type. Expected #{_base_models}, got #{object.class}"
        end
        return_values = {}
        included_methods.each do |method|
          return_value = object.send(method, args_for_method(method))
          # By default, we try to encode the return value from the method to JSON, if not,
          # is the user's responsibility to make sure that the return value is JSON-encodable.
          if return_value.class.include?(JSONConvertible)
            return_value = return_value.to_object_dictionary
          end
          return_values[method.to_s] = return_value
        end
        return return_values
      end

      def viewmodel_from_attributes(object)
        raise "Override base_models(*models) in order to use the ViewModel mixin." if _base_models.nil?
        unless _base_models.any? { |base_model| object.kind_of?(base_model) }
          raise "Incorrect object type. Expected #{_base_models}, got #{object.class}"
        end
        if object.respond_to?(:to_object_dictionary)
          return object.to_object_dictionary(included_attributes[object.class.to_s])
        else
          raise "#{object.class} does not include JSONConvertible." unless object.class.include?(JSONConvertible)
        end
      end
    end
  end
end
