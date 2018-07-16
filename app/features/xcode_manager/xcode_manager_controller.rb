require "set"

require_relative "../../shared/authenticated_controller_base"
require_relative "../../services/services"

module FastlaneCI
  # A controller to manage Xcode installations
  class XcodeManagerController < AuthenticatedControllerBase
    HOME = "/xcode_manager_erb"

    get HOME do
      locals = {
        title: "Xcode Manager",
        # Passing xcode versions to make sure to not
        # re-run this multiple times on a single request
        installed_xcode_versions: Services.xcode_manager_service.installed_xcode_versions,
        available_xcode_versions: Services.xcode_manager_service.available_xcode_versions,
        installing_xcode_versions: Services.xcode_manager_service.installing_xcode_versions
      }
      erb(:xcode_manager, locals: locals, layout: FastlaneCI.default_layout)
    end

    post "#{HOME}/install" do
      # TODO: add error handling for `version` parameter
      version = Gem::Version.new(params[:version])

      Services.xcode_manager_service.install_xcode!(
        version: version
      )

      redirect(HOME)
    end
  end
end
