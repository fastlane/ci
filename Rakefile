task :dev do
  sh "bundle exec rackup -p 8080 --env development"
end

task :devbootstrap do
  sh "bundle install"
  sh "npm install"
  sh "ln -sf ../../.pre-commit .git/hooks/pre-commit"
end

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
  task(default: :spec)
rescue LoadError
end
