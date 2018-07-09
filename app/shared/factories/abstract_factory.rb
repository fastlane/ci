module FastlaneCI
  # An abstract factory following the abstract factory design pattern.
  class AbstractFactory
    def create(params: {})
      not_implemented(__method__)
    end
  end
end
