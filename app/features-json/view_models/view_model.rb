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
  #        end
  #
  #        k = KlassModel.new
  #        o = OtherKlassModel.new
  #        viewmodel = KlassViewModel.viewmodel_from!(k, o)
  #        puts viewmodel # => { "KlassModel"=> { "attribute" => "hello", "other_attribute" => "world" },
  #                              "OtherKlassModel"=> { "another_attribute" => "foo", "other_other_attribute" => "bar" }
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
      # @return [Array<Symbol>] the included attributes for the given ViewModel. Defaults to all attributes.
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

      # Creates the ViewModel (in shape of a Hash) from a given object of a certain class type.
      # Defined by the base_model method.
      # @params [Any] objects
      # @return [Hash<String, Hash>] object dictionary representation for the ViewModel, where the key
      # is the name of the class and the value is object dictionary representation.
      def viewmodel_from!(*objects)
        viewmodel = {}
        objects.each do |object|
          viewmodel[object.class.to_s] = _viewmodel_from(object)
        end
        return viewmodel
      end

      private

      def _viewmodel_from(object)
        raise "Override base_model(model) in order to use the ViewModel mixin." if _base_models.nil?
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
