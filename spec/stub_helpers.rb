require "helper_functions"

module StubHelpers
  include HelperFunctions

  def stub_file_io
    File.stub(:write)
  end

  def stub_git_repos
    FastlaneCI::GitRepo.any_instance.stub(:initialize)
    FastlaneCI::GitRepo.any_instance.stub(:setup_repo)
    FastlaneCI::GitRepo.any_instance.stub(:clone)
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
