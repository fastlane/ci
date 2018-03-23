# frozen_string_literal: true

module FastlaneCI
  # A class to write files using the template design pattern
  class FileWriter
    # @return [String]
    attr_accessor :path

    # `locals` are template variables used in `file_template` method
    #
    # @return [Hash]
    attr_accessor :locals

    # Instantiates with a path to write to, and template local variables
    #
    # @param [String] path
    # @param [Hash]   locals
    def initialize(path:, locals: {})
      self.path = path
      self.locals = locals
    end

    # Writes the concrete class' template method (`file_template`) out to the
    # specified file `path`
    def write!
      File.write(self.path, file_template)
    end

    # Template method to be overridden by concretions
    #
    # @abstract
    # @return [String]
    def file_template
      not_implemented(__method__)
    end
  end
end
