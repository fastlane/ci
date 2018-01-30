module FastlaneCI
  class TestRunnerService
    attr_accessor :project
    attr_accessor :build_service
    attr_accessor :source
    attr_accessor :current_build
    attr_accessor :sha

    def initialize(project: nil, sha: nil, provider_credential: nil)
      self.project = project
      self.sha = sha

      # TODO: Services::BUILD_SERVICE doesn't work as the file isn't included
      # TODO: ugh, I'm doing something wrong, I think?
      json_folder_path = FastlaneCI::FastlaneApp::CONFIG_DATA_SOURCE.git_repo.git_config.local_repo_path
      self.build_service = FastlaneCI::BuildService.new(data_source: BuildDataSource.new(json_folder_path: json_folder_path))

      self.source = FastlaneCI::GitHubSource.source_from_provider_credential(
        provider_credential: provider_credential
      )
    end

    # Responsible for updating the build status in our local config
    # and on GitHub
    def update_build_status!
      # Create or update the local build file in the config directory
      build_service.add_build!(
        project: self.project,
        build: self.current_build
      )

      # Commit & Push the changes
      FastlaneCI::FastlaneApp::CONFIG_DATA_SOURCE.git_repo.commit_changes!

      # Let GitHub know we're already running the tests
      self.source.set_build_status!(
        repo: self.project.repo_config.git_url,
        sha: self.sha,
        state: self.current_build.status,
        target_url: nil
      )
    end

    def run
      builds = build_service.list_builds(project: self.project)

      if builds.count > 0
        new_build_number = builds.sort_by { |b| b.number }.last.number + 1
      else
        new_build_number = 1 # do we start with 1?
      end

      self.current_build = FastlaneCI::Build.new(
        project: self.project,
        number: new_build_number,
        status: :pending,
        timestamp: Time.now,
        duration: -1,
        sha: self.sha
      )
      update_build_status!

      start_time = Time.now
      
      # TODO: Replace with fastlane runner here
      command = "bundle update"
      puts "Running #{command}"
      Dir.chdir(project.repo_config.local_repo_path) do
        cmd = TTY::Command.new
        cmd.run(command)
      end

      # TODO: run tests here!
      duration = Time.now - start_time

      current_build.duration = duration
      current_build.status = :success

      self.update_build_status!
    rescue => ex
      # TODO: better error handling
      puts ex
      current_build.status = :failure # TODO: also handle failure
      self.update_build_status!
    end
  end
end
