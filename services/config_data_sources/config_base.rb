module FastlaneCI
  # TODO: move this somewhere else maybe @taquitos?
  # Base object used by all configuration things we support
  # e.g. Project
  class ConfigBase
    def attributes_to_persist
      []
    end

    # Basic output of class name + important attributes
    def to_s
      "#<#{self.class} " + attributes_to_persist.collect do |key|
        "@#{key}=#{self.send(key)}"
      end.join(", ") + ">"
    end
  end
end
