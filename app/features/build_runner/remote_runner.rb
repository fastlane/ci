require_relative "../../../agent/client"

module FastlaneCI
  class RemoteRunner
    include FastlaneCI::Logging

    def initialize(project_id)
      @client = Agent::Client.new("localhost")
    end

    def start
      file = File.open("/tmp/fastlane-ci.log", "w")
      file.sync = true
      success = true

      logs = @client.request_spawn("rake", "fastlane[actions]", env: { "GIT_URL" => "https://github.com/themoji/ios" })
      logs.each do |log|
        logger.info(log.inspect)
        file.write(log.message)

        if log.status != 0
          logger.error("WE HAVE AN ERROR!")
          success = false
        end
      end

      file.close

      return success
    end
  end
end
