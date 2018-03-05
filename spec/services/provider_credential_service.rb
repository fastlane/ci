require File.expand_path("../../spec_helper.rb", __FILE__)
require File.expand_path("../../../services/provider_credential_service.rb", __FILE__)

describe FastlaneCI::ProviderCredentialService do
  let (:credential) do
    GitHubProviderCredential.new(
      id: "id",
      email: "fake_email@gmail.com",
      api_token: "fake_api_token",
      provider_name: "github",
      full_name: "full_name"
    )
  end

  subject do
    FastlaneCI::ProviderCredentialService.new
  end

  before(:each) do
    stub_file_io
    stub_git_repos
    stub_services
  end

  describe "#create_provider_credential!" do
  end

  describe "#update_provider_credential!" do
  end
end
