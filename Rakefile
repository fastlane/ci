task :dev do
  sh "bundle exec rackup -o 0.0.0.0 -p 8080 --env development"
end

task :prod do
  sh "bundle exec rackup -p 8080 --env production"
end

task :hosted_prod_test do
  sh("FASTLANE_CI_ERB_CLIENT=1 DEBUG=1 FASTLANE_CI_DISABLE_REMOTE_STATUS_UPDATE=1 FASTLANE_CI_DISABLE_PUSHES=1 FASTLANE_CI_SKIP_RESTARTING_PENDING_WORK=1 bundle exec rackup --host 0.0.0.0 -p 8080 --env development")
end

task :devbootstrap do
  sh("bundle install")
  sh("brew install node") unless sh("npm -v")
  sh("npm install")
  sh("ln -sf ../../.pre-commit .git/hooks/pre-commit")
end

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
  task(default: :spec)
rescue LoadError
end
