require File.expand_path("../../../spec_helper.rb", __FILE__)
require File.expand_path("../../../../services/file_writers/file_writer.rb", __FILE__)

describe FastlaneCI::FileWriter do
  before(:each) do
    stub_file_io
  end

  let(:fixtures_path) do
    File.join(
      FastlaneCI::FastlaneApp.settings.root,
      "spec/fixtures/files/templates"
    )
  end

  let(:template_path) do
    File.join(fixtures_path, "file_template.json")
  end

  let(:template_string) do
    File.read(template_path)
  end

  subject do
    described_class.new(path: template_path)
  end

  describe "#write!" do
    it "opens and writes the `file_template` to the `path`" do
      subject.stub(:file_template) { template_string }
      file = double("file")

      File
        .should_receive(:open)
        .with(template_path, "w")
        .and_yield(file)

      file
        .should_receive(:write)
        .with(template_string)

      subject.write!
    end
  end

  describe "#file_template" do
    it "should raise not_implemented(__method__)" do
    end
  end
end
