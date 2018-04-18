require "rubygems"
require "bundler"
require "rack"
require "rack/contrib"

Bundler.require

require_relative "./launch"

FastlaneCI::Launch.take_off

# Adds support for JSON request bodies.
# The Rack parameter hash is populated by deserializing the JSON data provided
# in the request body when the Content-Type is application/json.
use(Rack::PostBodyContentTypeParser)

run(FastlaneCI::FastlaneApp)
