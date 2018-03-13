describe FastlaneCI do
  describe "docs" do
    Dir["features/*"].each do |feature_directory|
      next unless File.directory?(feature_directory)
      it "#{feature_directory} has a README.md" do
        readme_path = File.join(feature_directory, "README.md")
        expect(File.exist?(readme_path)).to eq(true), "Every directory in the `feature` area must have a README.md describing the scope and responsibilities of the classes (#{feature_directory})"

        content = File.read(readme_path)
        expect(content.length).to be > 20
        expect(content).to start_with("# `features/#{feature_directory}`")
      end
    end

    Dir["services/*"].each do |service_directory|
      next unless File.directory?(service_directory)
      it "#{service_directory} has a README.md" do
        readme_path = File.join(service_directory, "README.md")
        expect(File.exist?(readme_path)).to eq(true), "Every directory in the `feature` area must have a README.md describing the scope and responsibilities of the classes (#{service_directory})"
        expect(File.read(readme_path).length).to be > 20
      end
    end
  end
end
