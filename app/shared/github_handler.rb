require "octokit"
require_relative "logging_module"

# TODO: eventually we'll want to consider handling all these:
# when 400      Octokit::BadRequest
# when 401      Octokit::OneTimePasswordRequired
#               Octokit::Unauthorized
# when 403      Octokit::TooManyRequests
#               Octokit::TooManyLoginAttempts
#               Octokit::AbuseDetected
#               Octokit::RepositoryUnavailable
#               Octokit::UnverifiedEmail
#               Octokit::AccountSuspended
#               Octokit::Forbidden
# when 404      Octokit::BranchNotProtected
#               Octokit::NotFound
# when 405      Octokit::MethodNotAllowed
# when 406      Octokit::NotAcceptable
# when 409      Octokit::Conflict
# when 415      Octokit::UnsupportedMediaType
# when 422      Octokit::UnprocessableEntity
# when 451      Octokit::UnavailableForLegalReasons
# when 400..499 Octokit::ClientError <- is a base class for 400 errors
# when 500      Octokit::InternalServerError
# when 501      Octokit::NotImplemented
# when 502      Octokit::BadGateway
# when 503      Octokit::ServiceUnavailable
# when 500..599 Octokit::ServerError <- is a base class for 500 errors

module FastlaneCI
  # Responsible for catching all the errors that can happen when we use the octokit framework and
  # retrying any action that is retryable (server errors)
  # We could modify it in the future to provide better error messages, but for now, just focus on server stuff.
  # TODO: handle if the user doesn't have write permission and they are trying to do some writing
  module GitHubHandler
    include FastlaneCI::Logging

    def self.included(klass)
      klass.extend(self)
    end

    def github_action(client, &block)
      # `retry` retains the variables through iterations so we assign to 0 the first time.
      retry_count ||= 0
      if client.kind_of?(Octokit::Client)
        begin
          if client.rate_limit!.remaining.zero?
            sleep_time = client.rate_limit!.resets_in
            logger.debug("Rate Limit exceeded, sleeping for #{sleep_time} seconds")
            sleep(sleep_time)
          end
        rescue Octokit::TooManyRequests => ex
          logger.error(ex)
          raise ex
        rescue Octokit::Unauthorized => ex # Maybe the token does not give access to rate limits.
          logger.error(ex)
        end
      end
      begin
        return block.call
      rescue Octokit::ServerError => ex
        if (retry_count += 1) < 5
          # exponential backoff
          sleep_length = 2**retry_count
          logger.debug("A GitHub action failed, sleeping for #{sleep_length} seconds and retrying")
          sleep(sleep_length)
          retry
        end

        raise ex
      end
    end
  end
end
