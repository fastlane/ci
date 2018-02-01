require "rubygems"
require "bundler"

Bundler.require

require_relative "./launch"

FastlaneCI::Launch.take_off
run(FastlaneCI::FastlaneApp)
