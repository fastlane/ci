require "sinatra/base"
require "sinatra/reloader"
require_relative "services/data_sources/json_data_source"

module FastlaneCI
  class FastlaneApp < Sinatra::Base
    configure(:development) do |configuration|
      register Sinatra::Reloader
      configuration.also_reload "features/dashboard/dashboard_controller.rb"
      configuration.after_reload do
        puts "reloaded"
      end
    end

    DATA_SOURCE = JSONDataSource.new

    get "/" do
      redirect("/dashboard")
    end

    get "/favico.ico" do
      "nope"
    end
  end
end
