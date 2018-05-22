require "spec_helper"
require "app/workers/check_for_fastlane_ci_update_worker"

describe FastlaneCI::CheckForFastlaneCIUpdateWorker do
  let(:service) do
    FastlaneCI::CheckForFastlaneCIUpdateWorker.new
  end

  describe "#check_for_update" do
    it "doesn't do antyhing if no new version is available" do
      latest_release = Gem::Version.new("1.3.0")

      expect(service).to receive(:currently_running_version).and_return(latest_release)
      expect(service).to receive(:version_of_latest_release).and_return(latest_release)
      expect(FastlaneCI::Services.notification_service).not_to(receive(:create_notification!))

      service.check_for_update
    end

    it "triggers an update notification if an update is available" do
      latest_release = Gem::Version.new("1.3.0")

      expect(service).to receive(:currently_running_version).and_return(Gem::Version.new("1.1.4"))
      allow(service).to receive(:version_of_latest_release).and_return(latest_release)
      expect(FastlaneCI::Services.notification_service).to receive(:create_notification!)

      service.check_for_update
    end
  end
end
