# Add `typesafe_accessor` to Class.
class Class
  # This method allows to declare attributes using type-safe annotations.
  #   @example
  #     class Klass
  #       typesafe_accessor :name, String
  #     end
  #     k = Klass.new
  #     k.name = "Hello" => "Hello"
  #     k.name = 1 => ArgumentError. Invalid type: expected: String got Integer.
  #
  def typesafe_accessor(name, type)
    attr_name = name.to_s

    self.class_eval(%{
      def #{attr_name}
        return @#{attr_name}
      end
    })

    self.class_eval(%{
      def #{attr_name}=(val)
        if val.is_a? #{type}
          @#{attr_name} = val
        else
          raise ArgumentError.new("Invalid type, expected: #{type} got \#\{val.class\}.")
        end
      end
    })
  end
end
