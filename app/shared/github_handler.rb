require "octokit"
require "faraday"
require "socket"
require "net/http"
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
      if client.kind_of?(Octokit::Client)
        # Inject Faraday::Request::Retry to the client if necessary
        client = inject_retry_middleware(client)
        # `rate_limit_retry_count` retains the variables through iterations so we assign to 0 the first time.
        rate_limit_retry_count ||= 0
        begin
          if client.rate_limit!.remaining.zero?
            rate_limit_reset_time_length = client.rate_limit!.resets_in
            logger.debug("Rate Limit exceeded, sleeping for #{rate_limit_reset_time_length} seconds")
            sleep(rate_limit_reset_time_length)
          end
        rescue Octokit::Unauthorized => ex # Maybe the token does not give access to rate limits.
          logger.error("Your GitHub Personal Auth Token is not unauthorized to check the rate_limit")
          logger.error(ex)
          # We want to die now, since this is a server config issue
          # Ultimately, this shouldn't kill the server, but rather, send a notification
          # TODO: accomplish the above ^
          raise ex
        rescue Octokit::ServerError, Octokit::TooManyRequests, Faraday::ConnectionFailed => ex
          if (rate_limit_retry_count += 1) < 5
            rate_limit_sleep_length = 2**rate_limit_retry_count
            logger.debug("Unable to get rate limit, sleeping for #{rate_limit_sleep_length} seconds and retrying")
            logger.debug(ex)
            sleep(rate_limit_sleep_length)
            retry
          end
          logger.debug("Unable to get rate limit after retrying multiple time, failing")
          # Ultimately, this shouldn't kill the server, but rather, send a notification
          # TODO: accomplish the above ^
          raise ex
        end
      end

      # `retry_count` retains the variables through iterations so we assign to 0 the first time.
      retry_count ||= 0
      begin
        return block.call(client)
      rescue Octokit::ServerError, Octokit::TooManyRequests, Faraday::ConnectionFailed => ex
        if (retry_count += 1) < 5
          # exponential backoff
          sleep_length = 2**retry_count
          logger.debug("A GitHub action failed, sleeping for #{sleep_length} seconds and retrying")
          logger.debug(ex)
          sleep(sleep_length)
          retry
        end
        logger.debug("Unable to perform GitHub action after retrying multiple time, failing")
        # Ultimately, this shouldn't kill the server, but rather, send a notification
        # TODO: accomplish the above ^
        raise ex
      rescue Octokit::Unauthorized => ex # Maybe the token does not give access to rate limits.
        logger.error("Your GitHub Personal Auth Token is unauthorized to perform the github action")
        logger.error(ex)
        # Ultimately, this shouldn't kill the server, but rather, send a notification
        # TODO: accomplish the above ^
        raise ex
      end
    end

    private

    def inject_retry_middleware(client)
      unless client.middleware.handlers.include?(Faraday::Request::Retry)
        middleware_dup = client.middleware.dup
        client.middleware = middleware_dup
        client.middleware.insert_before(
          Faraday::Adapter::NetHttp,
          Faraday::Request::Retry,
          max: 3,
          interval: 0.5,
          interval_randomness: 0.5,
          backoff_factor: 2,
          exceptions: [
            Errno::ETIMEDOUT,
            "Timeout::Error",
            Faraday::Error::TimeoutError,
            Faraday::Error::RetriableResponse,
            SocketError
          ]
        )
      end
      return client
    end
  end
end
