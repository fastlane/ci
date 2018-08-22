# foreman is not included in the Gemfile, more context
# https://github.com/ddollar/foreman/pull/678#issuecomment-398211757

task :dev do
  unless system("which foreman", out: File::NULL)
    raise "`foreman` is now required for process management. `sudo gem install foreman`"
  end
  sh "foreman start -f Procfile.dev"
end

task :prod do
  unless system("which foreman", out: File::NULL)
    raise "`foreman` is now required for process management. `sudo gem install foreman`"
  end
  sh "foreman start"
end

task :dev_bootstrap do
  unless system("which brew")
    raise "`brew` is required. Please install brew. https://brew.sh/"
  end

  sh("bundle install")
  sh("gem install foreman")
  sh("brew install node") unless system("which npm")
  sh("npm install")
  sh("ln -sf ../../.pre-commit .git/hooks/pre-commit")
end

# It seems like mapping ports in Docker requires --host which can break hosting in VMs
# So we'll just keep some docker-specific tasks down here
namespace :docker do
  desc "Run in a Docker container in production mode"
  task :prod do
    sh "bundle exec rackup --host 0.0.0.0 --port 8080 --env production"
  end

  desc "Run in a Docker container with debugging on, no pushes, and no restarting work to help test config stuff"
  task :prod_test do
    # rubocop:disable Metrics/LineLength
    sh("FASTLANE_CI_ERB_CLIENT=1 DEBUG=1 FASTLANE_CI_DISABLE_REMOTE_STATUS_UPDATE=1 FASTLANE_CI_DISABLE_PUSHES=1 FASTLANE_CI_SKIP_RESTARTING_PENDING_WORK=1 bundle exec rackup --host 0.0.0.0 --port 8080 --env development")
    # rubocop:enable Metrics/LineLength
  end

  desc "Bootstrap for running in a Docker container"
  task :dev_bootstrap do
    sh("bundle install")
    sh("npm install")
  end
end

task :generate_protos do
  sh "bundle exec grpc_tools_ruby_protoc -I protos/ --ruby_out=./protos --grpc_out=./protos protos/*.proto"
end

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
  task(default: :spec)
rescue LoadError
end
