require_relative "code_hosting_sources/code_hosting"

module FastlaneCI
  class CodeHostingService
    attr_accessor :code_hosting_source

    def initialize(code_hosting_source: FastlaneCI::FastlaneApp::CODE_HOSTING_SOURCE)
      self.code_hosting_source = code_hosting_source
    end

    def repos
      self.code_hosting.repos
    end

    def session_valid?
      self.code_hosting_source.session_valid?
    end
  end
end
