task :dev do
  sh "bundle exec rackup -p 8080 --env development"
end

task :prod do
  sh "bundle exec rackup -p 8080 --env production"
end

task :devbootstrap do
  sh "bundle install"
  sh("brew install node") unless sh("npm -v")
  sh "npm install"
  sh "ln -sf ../../.pre-commit .git/hooks/pre-commit"
end

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
  task(default: :spec)
rescue LoadError
end
