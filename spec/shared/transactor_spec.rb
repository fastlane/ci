require_relative "../../shared/transactor"

module FastlaneCI
  describe Transactor do
    let(:transactor) { Transactor.new }

    context "transaction lifecycle" do
      before do
        allow(transactor).to receive(:start_transaction)
        allow(transactor).to receive(:end_transaction)
      end

      it "runs the block in the transaction and returns its value" do
        expected = "hello transaction"
        result = transactor.transaction do
          expected
        end

        expect(result).to eq(expected)
      end

      it "rolls back the transaction if an error is thrown in the block" do
        expect(transactor).to receive(:rollback)

        transactor.transaction do
          raise "Error"
        end
      end
    end
  end
end
