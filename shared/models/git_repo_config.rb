require "securerandom"
require_relative "../logging_module"

module FastlaneCI
  # Contains the metadata about a git repo
  class GitRepoConfig
    include FastlaneCI::Logging

    attr_accessor :id
    attr_accessor :git_url
    attr_accessor :description   
    attr_accessor :name 
    attr_accessor :hidden # Do we want normal users to be able to see this?   

    def self.new_id
      return SecureRandom.uuid
    end

    def initialize(id: nil, git_url: nil, description: nil, name: nil, hidden: false)
      @id = id
      @git_url = git_url
      @description = description
      @name = name
      @hidden = hidden
    end
  end
end
