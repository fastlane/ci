require "helper_functions"

module StubHelpers
  include HelperFunctions

  def stub_file_io
    File.stub(:write)
  end

  def stub_git_repos
    fake_git_config = FastlaneCI::GitRepoConfig.new(
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
    FastlaneCI::GitRepo.any_instance.stub(:initialize)
    FastlaneCI::GitRepo.any_instance.stub(:setup_repo)
    FastlaneCI::GitRepo.any_instance.stub(:fetch)
    FastlaneCI::GitRepo.any_instance.stub(:git_config).and_return(fake_git_config)
    FastlaneCI::GitRepo.any_instance.stub(:repo_auth).and_return(fake_repo_auth)
    FastlaneCI::GitRepo.any_instance.stub(:clone)
    FastlaneCI::GitRepo.any_instance.stub(:pull)
    FastlaneCI::GitRepo.any_instance.stub(:push)
    FastlaneCI::GitRepo.any_instance.stub(:commit_changes!)
  end

  def stub_services
    FastlaneCI::Services.stub(:ci_config_git_repo_path).and_return(git_repo_path)

    FastlaneCI::Services.stub(:project_service).and_return(
      FastlaneCI::ProjectService.new(
        project_data_source: FastlaneCI::JSONProjectDataSource.create(
          git_repo, user: ci_user
        )
      )
    )

    FastlaneCI::Services.stub(:user_service).and_return(
      FastlaneCI::UserService.new(
        user_data_source: FastlaneCI::JSONUserDataSource.create(git_repo_path)
      )
    )

    FastlaneCI::Services.stub(:ci_user).and_return(ci_user)

    FastlaneCI::Services.stub(:build_service).and_return(
      FastlaneCI::BuildService.new(
        build_data_source: FastlaneCI::JSONBuildDataSource.create(git_repo_path)
      )
    )
  end
end
