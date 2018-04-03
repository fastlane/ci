require_relative "transactor"

module FastlaneCI
  # Runs 'transactions' in the git repository
  class GitTransactor < Transactor
    attr_reader :git_repo

    def initialize(git_repo:)
      @git_repo = git_repo
    end

    def in_progress?
      !git_repo.status.empty?
    end

    def start_transaction
      # NOP for git, just check if the repo is clean
      raise "Your git repo is dirty" if in_progress?
    end

    def end_transaction
      git_repo.commit_changes! if in_progress?
    end

    def rollback(error:)
      # TODO: log error
      git_repo.reset_hard!
    end
  end
end
