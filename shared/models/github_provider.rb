require_relative "provider"
module FastlaneCI
  # GitHub Provider class
  class GitHubProvider < Provider
    attr_accessor :email # email used on github
    attr_accessor :api_token # api token from github

    def initialize(email: nil, api_token: nil)
      @email = email
      @api_token = api_token
      @type = PROVIDER_TYPES[:github]
    end

    # TODO
    def dictionary_value
      return { "email" => @email, "api_token" => @api_token }
    end
  end
end
