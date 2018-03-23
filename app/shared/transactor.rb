module FastlaneCI
  # Abstract base for handling transactions for any backend (e.g. git)
  class Transactor
    # Runs given block inside of a transaction, automatically starting and ending it. Throw an exception to roll back
    def transaction
      self.start_transaction
      result = yield
      return result
    rescue StandardError => ex
      self.rollback(error: ex)
    ensure
      self.end_transaction
    end

    # true if called while a transaction is in progress
    def in_progress?
      not_implemented(__method__)
    end

    # Start a new transaction. Note some backends might be limited to a single transaction at a time
    def start_transaction
      not_implemented(__method__)
    end

    # End the current transaction
    def end_transaction
      not_implemented(__method__)
    end

    # Rolls back the current transaction
    def rollback(error:)
      not_implemented(__method__)
    end
  end
end
