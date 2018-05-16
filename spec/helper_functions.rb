module HelperFunctions
  def fixture_path
    File.join(FastlaneCI::FastlaneApp.settings.root, "spec/fixtures/files/")
  end

  def provider_credential
    FastlaneCI::GitHubProviderCredential.new(email: "test_user", api_token: nil)
  end

  def git_repo
    FastlaneCI::GitHubRepoConfig.new(
      id: "fastlane-ci-config",
      git_url: "https://github.com/fake_user/fake_config",
      description: "Contains the fastlane.ci configuration",
      name: "fastlane ci",
      hidden: true
    )
  end

  def git_repo_path
    "fake_repo_path"
  end

  def ci_user
    FastlaneCI::User.new(
      email: "test_user",
      password_hash: "password_hash",
      provider_credentials: [provider_credential]
    )
  end

  def environment_variables
    return {
      encryption_key: "encryption_key",
      ci_user_password: "ci_user_password",
      repo_url: "https://github.com/user_name/repo_name",
      initial_onboarding_user_api_token: "initial_onboarding_user_api_token"
    }
  end
end
