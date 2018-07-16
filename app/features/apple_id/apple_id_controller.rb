require "set"

require_relative "../../shared/authenticated_controller_base"
require_relative "../../services/services"

module FastlaneCI
  # A CRUD controller to manage Apple ID credentials
  class AppleIDController < AuthenticatedControllerBase
    HOME = "/apple_ids_erb"

    get HOME do
      locals = { title: "Apple IDs" }
      erb(:apple_ids, locals: locals, layout: FastlaneCI.default_layout)
    end

    # Create a new Apple ID on fastlane.ci
    post "#{HOME}/create" do
      new_apple_id = nil
      if valid_params?(params, post_parameter_list_for_validation)
        new_apple_id = Services.apple_id_service.create_apple_id!(
          user: params[:user],
          password: params[:password],
          prefix: params[:prefix]
        )
      end

      if new_apple_id.nil?
        # Print out error message here, either parameters were invalid,
        # or key was already taken
        logger.error("Something went wrong")
      end

      redirect(HOME)
    end

    # More methods could be taken from EnvironmentVariablesController

    private

    #####################################################
    # @!group Data: View-specific data
    #####################################################

    # @return [Array[AppleID]]
    def apple_ids
      return Services.apple_id_service.apple_ids
    end

    #####################################################
    # @!group Params: View parameters required
    #####################################################

    # @return [Set[Symbol]]
    def post_parameter_list_for_validation
      # Currently we don't make use of `prefix`
      # The prefix is used for iTunes Transporter
      # https://github.com/fastlane/ci/issues/1082
      return Set.new(%w(user password))
    end
  end
end
