source("https://rubygems.org")

# Please **always** use the follow notation to define a dependency:
#
# gem "gem_name", ">= 1.3.4", "< 2.0.0" # comment on why we need this dependency
#
# Note:
#   - Always add a comment on why this dependency is needed
#   - Always use `>=` and `<` to define a version range:
#     - This way we can require a minimum version, including a hotfix while also
#     - defining a maximum version (major = breaking)
#     - If we used `~>` we can't define a patch release without being too strict with our locking
#

# Sinatra
gem "faye-websocket", ">= 0.10.7", "< 1.0.0" # web socket connection for Sinatra
gem "sinatra", "= 2.0.3" # Our web application library
gem "sinatra-contrib", ">= 2.0.3", "< 3.0.0" # includes some Sinatra helper methods
gem "sinatra-flash" # renders error messages in the browser - remove once we switched to new frontend

# web server that we need to support web socket connections with sinatra
gem "thin", ">= 1.7.2", "< 2.0.0"

# Best password hashing to-date
gem "bcrypt", ">= 3.1.11", "< 4.0.0"

# Running shell commands
gem "tty-command", ">= 0.7.0", "< 1.0.0"

# Communication with GitHub
gem "octokit", ">= 4.8.0", "< 5.0.0"

# Load the `.keys` dotenv file we use to store encryption data
gem "dotenv", ">= 2.4.0", "< 3.0.0"

# Caching for octokit operations
gem "faraday-http-cache", ">= 2.0.0", "< 3.0.0"

# We have rubocop as runtime dependency for now
# as we run code style verification for fastlane.ci
# TODO: We should remove this before the public release
gem "rubocop"

# Job scheduler for Ruby (at, cron, in and every jobs).
gem "rufus-scheduler", ">= 3.5.0", "< 4.0.0"

# Access to Google Cloud Platform Storage API.
gem "google-cloud-storage", git: "https://github.com/krausefx/google-cloud-ruby", branch: "patch-1"
# TODO: Should be ">= 1.12.0", "< 2.0" once https://github.com/GoogleCloudPlatform/google-cloud-ruby/pull/2099 is merged

# Manage CI dependencies.
gem "bundler", ">= 1.16.0", "< 2.0.0"

# Manage JWT authentication tokens.
gem "jwt", ">= 2.1.0", "< 3.0.0"

# Manage Xcode installations for the user
gem "xcode-install", ">= 2.4.0", "< 3.0.0"

# fastlane dependencies
# TODO: point to minimum release instead of GitHub once
#  we shipped a new release

# Interprocess communication
gem "grpc", ">= 1.11.0", "< 2.0.0"

# state machine for ruby objects
gem "micromachine", ">= 3.0.0", "< 4.0.0"

# Internal projects
gem "fastfile-parser", git: "https://github.com/fastlane/fastfile-parser", require: false
gem "fastlane", git: "https://github.com/fastlane/fastlane"
gem "taskqueue", git: "https://github.com/fastlane/TaskQueue", require: false

# External projects
gem "git", git: "https://github.com/fastlane/ruby-git", require: false # Interact with git locally

group :test, :development do
  gem "coveralls"
  gem "grpc-tools"
  gem "overcommit"
  gem "pry"
  gem "pry-byebug"
  gem "rack-test", require: "rack/test"
  gem "rake"
  gem "rspec"
  gem "timecop", ">= 0.9.1", "< 1.0.0"
  gem "webmock", ">= 3.4.1", "< 3.5.0"
end
