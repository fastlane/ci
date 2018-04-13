source("https://rubygems.org")

# Sinatra
gem "faye-websocket", ">= 0.10.7", "< 1.0.0" # web socket connection for Sinatra
gem "sinatra", ">= 2.0.1", "< 3.0.0" # Our web application library
gem "sinatra-contrib", ">= 2.0.0", "< 3.0.0" # TODO: document why we have this here @taquitos

# web server that we need to support web socket connections with sinatra
gem "thin", ">= 1.7.2", "< 2.0.0"

# Best password hashing to-date
gem "bcrypt", ">= 3.1.11", "< 4.0.0"

# Running shell commands
gem "tty-command", ">= 0.7.0", "< 1.0.0"

# Communication with GitHub
gem "octokit", ">= 4.8.0", "< 5.0.0"

# Local git checkouts, commits, etc.
gem "git", ">= 1.3.0", "< 2.0.0"

gem "dotenv", ">= 2.2.1", "< 3.0.0"

# Caching for octokit operations
gem "faraday-http-cache"

# We have rubocop as runtime dependency for now
# as we run code style verification for fastlane.ci
# TODO: We should remove this before the public release
gem "rubocop"

# Job scheduler for Ruby (at, cron, in and every jobs).
gem "rufus-scheduler"

# Access to Google Cloud Platform Storage API.
gem "google-cloud-storage", "~> 1.5.0"

# Manage CI dependencies.
gem "bundler", "~> 1.16.0"

# GraphQL Ruby bindings.
gem "graphql"

# fastlane dependencies
# TODO: point to minimum release instead of GitHub once
# 	we shipped a new release
gem "fastfile-parser", git: "https://github.com/fastlane/fastfile-parser", require: false
gem "fastlane", git: "https://github.com/fastlane/fastlane"
gem "taskqueue", git: "https://github.com/fastlane/TaskQueue", require: false

group :test, :development do
  gem "coveralls"
  gem "pry"
  gem "pry-byebug"
  gem "rack-test", require: "rack/test"
  gem "rake"
  gem "rspec"
end
