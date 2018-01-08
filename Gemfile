source("https://rubygems.org")

# Sinatra
gem "sinatra", ">= 2.0.0", "< 3.0"
gem "sinatra-contrib", ">= 2.0.0", "< 3.0" # TODO: document why we have this here @taquitos

# Running shell commands
gem "tty-command", ">= 0.7.0", "< 1.0.0"

# Communication with GitHub
gem "octokit", ">= 4.8.0", "< 5.0.0"

# fastlane dependencies
# gem "fastlane" # disabled for now, until we need it

group :test, :development do
  gem "pry"
  gem "rack-test", require: "rack/test"
  gem "rake"
  gem "rspec"
  gem "rubocop"
end
