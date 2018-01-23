require_relative "../../shared/authenticated_controller_base"

module FastlaneCI
  class ProjectController < AuthenticatedControllerBase
    HOME = "/projects"

    # Note: The order IS important for Sinatra, so this has to be
    # above the other URL
    #
    # TODO: this should actually be a POST request
    get "#{HOME}/*/trigger" do |project_id|
      project = self.user_project_with_id(project_id: project_id)

      repo = FastlaneCI::GitRepo.new(git_config: project.repo_config)

      # TODO: Obviously we're not gonna run fastlane
      # - on the web thread
      # - through a shell command, but using a socket instead
      # but this is just for the prototype (best type)
      # So all the code below can basically be moved over
      # to some kind of job queue that will be worked off
      current_github_provider = self.check_and_get_provider

      current_sha = repo.git.log.first.sha
      # Tell GitHub we're running CI for this...
      FastlaneCI::GitHubSource.source_from_provider(provider_credential: current_github_provider).set_build_status!(
        repo: project.repo_config.git_url,
        sha: current_sha,
        state: :pending,
        target_url: nil
      )

      begin
        # Dir.chdir(repo.path) do
        # Bundler.with_clean_env do
        # cmd = TTY::Command.new
        # cmd.run("bundle update")
        # cmd.run("bundle exec fastlane tests")
        # end
        # end
      rescue StandardError => ex
        # TODO: this will be refactored anyway, to the proper fastlane runner
      end

      FastlaneCI::GitHubSource.source_from_provider(provider).set_build_status!(
        repo: project.repo_config.git_url,
        sha: current_sha,
        state: :success,
        target_url: nil
      )
      # We don't even need danger to post test results
      # we can post the test results as a nice table as a GitHub comment
      # easily here, as we already have access to the test failures
      # None of the CI does that for whatever reason, but we can actually show the messages

      # redirect("#{HOME}/#{project_id}")
      "All done"
    end

    get "#{HOME}/*" do |project_id|
      project = self.user_project_with_id(project_id: project_id)

      locals = {
        project: project,
        title: "Project #{project.project_name}"
      }
      erb(:project, locals: locals, layout: FastlaneCI.default_layout)
    end
  end
end
