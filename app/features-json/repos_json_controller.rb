require_relative "api_controller"
require_relative "./view_models/repo_view_model"
require_relative "./view_models/lane_view_model"

module FastlaneCI
  # Controller for providing all data relating to projects
  class RepositoryJSONController < APIController
    HOME = "/data/repos"

    get HOME do
      repos = github_service.repos

      all_repos_view_models = repos.map do |repo|
        RepoViewModel.new(repo: repo)
      end

      json(all_repos_view_models)
    end

    # Accepts the repo full name and branch as query params
    # Ex. "../repos/lanes?repo_full_name=nakhbari%2FHelloWorld&branch=master"
    get "#{HOME}/lanes" do
      repo_full_name = params[:repo_full_name]
      branch = params[:branch]

      selected_repo = github_service.repos.detect do |repo|
        repo_full_name == repo[:full_name]
      end

      if selected_repo.nil?
        raise "Could not find repo, check that your github token has access to repo: #{repo_full_name}}"
      end

      fastfile_peeker = FastlaneCI::FastfilePeeker.new(
        provider_credential: current_user_provider_credential,
        notification_service: FastlaneCI::Services.notification_service
      )
      repo_config = GitHubRepoConfig.from_octokit_repo!(repo: selected_repo)

      fastfile_parser = fastfile_peeker.fastfile(
        repo_config: repo_config,
        sha_or_branch: branch
      )

      json(fetch_available_lanes(fastfile_parser))
    end

    def github_service
      FastlaneCI::GitHubService.new(provider_credential: current_user_provider_credential)
    end

    def fetch_available_lanes(fastfile_parser)
      # we don't want to show `_before_all_block_`, `_after_all_block_` and `_error_block_`
      # or a private lane as an available lane
      lanes = []
      fastfile_parser.tree.each do |platform, value|
        value.each do |lane_name, lane_content|
          if lane_name.to_s.empty? ||
             lane_name.to_s.end_with?("_block_") ||
             lane_content[:private] == true
            next
          end
          lane_platform = platform.nil? ? :no_platform : platform
          lanes << LaneViewModel.new(lane_name: lane_name, lane_platform: lane_platform)
        end
      end
      return lanes
    end
  end
end
