require "sinatra/json"

module FastlaneCI
  ##
  # JSONParams mixin allows `params` method to return the params from the parsed request body
  #
  module JSONParams
    def params
      return @json_params if defined?(@json_params)

      request.body.rewind
      body = request.body.read

      return super if body.to_s.length == 0

      @json_params = JSON.parse(body)
      # make the accessor indifferent to strings or procs
      @json_params.default_proc = proc do |hash, key|
        if hash.key?(key.to_s)
          hash[key.to_s]
        end
      end

      query_params = super
      if query_params
        @json_params.merge!(query_params)
      end

      return @json_params
    end
  end
end
