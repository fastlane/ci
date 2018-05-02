require "sinatra/json"

module FastlaneCI
  ##
  # JSONController mixin allows `params` method to return the params from the parsed request body
  #
  module JSONController
    def self.included(mod)
      mod.before do
        if request.content_type != "application/json"
          logger.warn("JSON Controller expected json requests, but got `#{request.content_type}`")
        end
      end
    end

    def params
      return @json_params if defined?(@json_params)

      request.body.rewind
      body = request.body.read
      unless body.empty?
        @json_params = JSON.parse(body)
        # make the accessor indifferent to strings or procs
        @json_params.default_proc = proc do |hash, key|
          if hash.key?(key.to_s)
            hash[key.to_s]
          end
        end

        @json_params.merge!(super)

        return @json_params
      end
    end
  end
end
