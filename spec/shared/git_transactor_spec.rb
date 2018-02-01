require_relative "../../shared/git_transactor"

module FastlaneCI
  describe GitTransactor do
    let(:mock_repo) { "Mock Repo" }
    let(:transactor) { GitTransactor.new(git_repo: mock_repo) }

    it "reports that a transaction is in progress when the git repo is dirty" do
      expect(mock_repo).to receive(:status).and_return([:status_item])
      expect(transactor.in_progress?).to be(true)
    end

    it "fails when a new transaction is started when the repo is dirty" do
      expect(mock_repo).to receive(:status).and_return([:status_item])
      expect { transactor.start_transaction }.to raise_error(/dirty/)
    end

    it "resets the repo on rollback" do
      allow(mock_repo).to receive(:status).and_return([])

      expect(mock_repo).to receive(:reset_hard!)
      transactor.transaction do
        raise "Error"
      end
    end

    it "commits to the repo when the transaction succeeds" do
      expect(mock_repo).to receive(:status).and_return([])
      transactor.transaction do
        expect(mock_repo).to receive(:status).and_return([:status_item])
        expect(mock_repo).to receive(:commit_changes!)
      end
    end
  end
end
