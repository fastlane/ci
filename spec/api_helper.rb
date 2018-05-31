module APIHelper
  def jwt_secret
    "fastlane-ci-test"
  end

  # if you need to change the JWT payload from the header, please make sure you use the correct secret.
  def bearer_token
    "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwidXNlciI6IjEiLCJpYXQiOjEsImlzcyI6ImZhc3RsYW5lLmNpIn0.m2uYMjhLlRuA2TVr_5c5-xdWjSf3r7Ge0b53-cgJtdg"
  end
end

RSpec.configure do |config|
  config.include(APIHelper)
  config.define_derived_metadata(file_path: Regexp.new("spec/features-json/")) do |metadata|
    metadata[:type] = :api
  end
  config.before(:each, type: :api) do
    FastlaneCI::APIController.set(:jwt_secret, jwt_secret)
  end
end
