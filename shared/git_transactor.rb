require_relative "transactor"

module FastlaneCI
  # Runs 'transactions' in the git repository
  class GitTransactor < Transactor
    attr_accessor :git_repo

    def initialize(git_repo:)
      self.git_repo = git_repo
    end

    def in_progress?
      !self.git_repo.status.empty?
    end

    def start_transaction
      # NOP for git, just check if the repo is clean
      raise "Your git repo is dirty" if self.in_progress?
    end

    def end_transaction
      self.git_repo.commit_changes! if self.in_progress?
    end

    def rollback(error:)
      # TODO: log error
      self.git_repo.reset_hard!
    end
  end
end
