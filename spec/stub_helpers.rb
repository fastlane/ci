require "helper_functions"

module StubHelpers
  include HelperFunctions

  def stub_file_io
    allow(File).to receive(:write)
  end

  def stub_dot_keys
    allow_any_instance_of(FastlaneCI::DotKeysVariables).to receive(:all).and_return(environment_variables)
    allow_any_instance_of(FastlaneCI::DotKeysVariables).to receive(:encryption_key).and_return("encryption_key")
    allow_any_instance_of(FastlaneCI::DotKeysVariables).to receive(:ci_user_password).and_return("ci_user_password")
    allow_any_instance_of(FastlaneCI::DotKeysVariables).to receive(:ci_user_api_token).and_return("bot_user_api_token")
    allow_any_instance_of(FastlaneCI::DotKeysVariables).to receive(:repo_url).and_return("https://github.com/user_name/repo_name")
    allow_any_instance_of(FastlaneCI::DotKeysVariables).to receive(:initial_onboarding_user_api_token).and_return("initial_onboarding_user_api_token")
  end

  def stub_git_repos
    fake_git_config = FastlaneCI::GitHubRepoConfig.new(
      id: "Fake id",
      git_url: "Not a real url",
      description: "Fake git repo config",
      name: "Fake repo",
      full_name: "Fake repo"
    )

    fake_repo_auth = FastlaneCI::GitRepoAuth.new(
      remote_host: "fake.host.google.com",
      username: "fake_taquitos",
      full_name: "taquitos fake name",
      auth_token: "fake auth token"
    )
    allow_any_instance_of(FastlaneCI::GitRepo).to receive(:initialize)
    allow_any_instance_of(FastlaneCI::GitRepo).to receive(:setup_repo)
    allow_any_instance_of(FastlaneCI::GitRepo).to receive(:fetch)
    allow_any_instance_of(FastlaneCI::GitRepo).to receive(:git_config).and_return(fake_git_config)
    allow_any_instance_of(FastlaneCI::GitRepo).to receive(:repo_auth).and_return(fake_repo_auth)
    allow_any_instance_of(FastlaneCI::GitRepo).to receive(:clone)
    allow_any_instance_of(FastlaneCI::GitRepo).to receive(:local_folder).and_return(fixture_path)
  end

  def stub_services
    allow(FastlaneCI::Services).to receive(:ci_config_git_repo_path).and_return(git_repo_path)
    allow(FastlaneCI::Services).to receive(:project_service).and_return(
      FastlaneCI::ProjectService.new(
        project_data_source: FastlaneCI::JSONProjectDataSource.create(
          git_repo_path, user: ci_user
        )
      )
    )

    allow(FastlaneCI::Services).to receive(:user_service).and_return(
      FastlaneCI::UserService.new(
        user_data_source: FastlaneCI::JSONUserDataSource.create(git_repo_path)
      )
    )

    allow(FastlaneCI::Services).to receive(:ci_user).and_return(ci_user)
    allow(FastlaneCI::Services).to receive(:build_service).and_return(
      FastlaneCI::BuildService.new(
        build_data_source: FastlaneCI::JSONBuildDataSource.create(git_repo_path)
      )
    )
  end
end
