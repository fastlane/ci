require_relative "../shared/authenticated_controller_base"
require_relative "./view_models/repo_view_model"

module FastlaneCI
  # Controller for providing all data relating to projects
  class ProjectJSONController < AuthenticatedControllerBase
    HOME = "/data/repos"

    get HOME.to_s do
      provider_credential = check_and_get_provider_credential
      repos = FastlaneCI::GitHubService.new(provider_credential: provider_credential).repos

      all_repos_view_models = repos.map do |repo|
        RepoViewModel.new(repo: repo)
      end

      return all_repos_view_models.to_json
    end
  end
end
