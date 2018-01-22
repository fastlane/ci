require_relative "provider"
module FastlaneCI
  # GitHub Provider class
  class GitHubProvider < Provider
    attr_accessor :email # email used on github
    attr_accessor :api_token # api token from github

    def initialize(email: nil, api_token: nil)
      @email = email
      @api_token = api_token
      @provider_name = "GitHub"
      @type = PROVIDER_TYPES[:github]
    end

    def type
      return @type
    end

    def provider_name
      return @provider_name
    end

    # TODO
    def dictionary_value
      return { "email" => @email, "api_token" => @api_token }
    end
  end
end
