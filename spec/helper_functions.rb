module HelperFunctions
  def provider_credential
    FastlaneCI::GitHubProviderCredential.new(email: "test_user", api_token: nil)
  end

  def git_repo
    FastlaneCI::GitRepoConfig.new(
      id: "fastlane-ci-config",
      git_url: "https://github.com/fake_user/fake_config",
      description: "Contains the fastlane.ci configuration",
      name: "fastlane ci",
      hidden: true
    )
  end

  def git_repo_path
    git_repo.local_repo_path
  end

  def ci_user
    FastlaneCI::User.new(
      email: "test_user",
      password_hash: "password_hash",
      provider_credentials: [provider_credential]
    )
  end
end
