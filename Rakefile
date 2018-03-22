task :dev do
  sh "bundle exec rackup -p 8080 --env development"
end

task :devbootstrap do
  #sh "git submodule update --init --recursive"
  sh "ln -sf .pre-commit .git/hooks/pre-commit"
end

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task :default => :spec
rescue LoadError
end
