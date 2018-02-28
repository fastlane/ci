source("https://rubygems.org")

# Sinatra
gem "sinatra", ">= 2.0.1", "< 3.0.0"
gem "sinatra-contrib", ">= 2.0.0", "< 3.0.0" # TODO: document why we have this here @taquitos

# Best password hashing to-date
gem "bcrypt", ">= 3.1.11", "< 4.0.0"

# Running shell commands
gem "tty-command", ">= 0.7.0", "< 1.0.0"

# Communication with GitHub
gem "octokit", ">= 4.8.0", "< 5.0.0"

# Local git checkouts, commits, etc.
gem "git", ">= 1.3.0", "< 2.0.0"

gem "dotenv", ">= 2.2.1", "< 3.0.0"

# Related to fastfile-parser project, Ruby language parsing
gem "parser", ">= 2.4.0.2", "< 2.5.0.0"
gem "unparser", ">= 0.2.6", "< 1.0.0"

# We have rubocop as runtime dependency for now
# as we run code style verification for fastlane.ci
# TODO: We should remove this before the public release
gem "rubocop"

# Job scheduler for Ruby (at, cron, in and every jobs).
gem "rufus-scheduler"

# fastlane dependencies
# TODO: point to minimum release instead of GitHub once
# 	we shipped a new release
gem "fastlane", git: "https://github.com/fastlane/fastlane"

group :test, :development do
  gem "pry"
  gem "pry-byebug"
  gem "rack-test", require: "rack/test"
  gem "rake"
  gem "rspec"
end
