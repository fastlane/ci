require_relative "../../shared/json_convertible"

module FastlaneCI
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
  #         base_model(KlassModel)
  #        end
  #
  #       k = KlassModel.new
  #       viewmodel = KlassViewModel.viewmodel_from!(object: k)
  #       viewmodel # => { "attribute" => "hello", "other_attribute" => "world" }
  #
  #       class OtherKlassViewModel
  #         include ViewModel
  #         base_model(KlassModel)
  #
  #         def self.included_attributes
  #           return [:@attribute]
  #         end
  #       end
  #
  #       other_viewmodel = OtherKlassViewModel.viewmodel_from!(object: k)
  #       other_viewmodel # => { "attribute" => "hello" }
  #
  module ViewModel
    class << self
      def included(base)
        base.extend(ClassMethods)
      end
    end

    # Add this as Class Methods.
    module ClassMethods
      # Required method to be called overriden by the created ViewModel
      # in order to indicate which class is the Model from which we are creating the ViewModel form.
      # @param [Class]
      def base_model(model)
        @base_model = model
      end

      # An array of the included attributes of the base_model to be included in the ViewModel.
      # @return [Array<Symbol>] the included attributes for the given ViewModel. Defaults to all attributes.
      def included_attributes
        return @base_model.instance_variables
      end

      # Creates the ViewModel (in shape of a Hash) from a given object of a certain class type.
      # Defined by the base_model method.
      # @params [Any] object
      # @return [Hash] object dictionary representation for the ViewModel.
      def viewmodel_from(object)
        raise "Override base_model(model) in order to use the ViewModel mixin." if @base_model.nil?
        raise "Incorrect object type. Expected #{@base_model}, got #{object.class}" unless object.kind_of?(@base_model)
        if object.respond_to?(:to_object_dictionary)
          return object.to_object_dictionary(ignore_instance_variables: object.instance_variables - included_attributes)
        else
          raise "#{@base_model} does not include JSONConvertible." unless @base_model.include?(JSONConvertible)
        end
      end
    end
  end
end
