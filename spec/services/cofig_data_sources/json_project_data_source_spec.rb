require "spec_helper"
require "app/shared/models/project"
require "app/services/config_data_sources/json_project_data_source"

describe FastlaneCI::JSONProjectDataSource do
  before(:each) do
    stub_file_io
    stub_git_repos
    stub_services
  end

  subject do
    FastlaneCI::JSONProjectDataSource.create(git_repo_path, user: ci_user)
  end

  let(:projects) do
    project_params.map { |params| FastlaneCI::Project.new(params) }
  end

  describe "#project_exist?" do
    before(:each) do
      allow(subject).to receive(:projects).and_return(projects)
    end

    context "project doesn't exist" do
      it "returns `false` when a project does not exist for given name" do
        expect(subject.project_exist?(new_project_name)).to be(false)
      end
    end

    context "project exists" do
      it "returns `true` if a project exists for given name" do
        expect(subject.project_exist?(first_project_name)).to be(true)
      end
    end
  end

  describe "#create_project!" do
    before(:each) do
      allow(subject).to receive(:projects).and_return(projects)
    end

    context "project doesn't exist" do
      it "returns `Project` object when a new project is created" do
        expect(subject.create_project!(new_project_params)).to be_an_instance_of(FastlaneCI::Project)
      end
    end

    context "project exists" do
      let(:old_project_params) do
        project_params.first.tap do |hs|
          hs.delete(:id)
          hs[:name] = hs.delete(:project_name)
        end
      end

      it "returns `nil` if the project already exists" do
        expect(File).not_to(receive(:write))
        expect(subject.create_project!(old_project_params)).to be_nil
      end
    end
  end

  describe "#update_project!" do
    let(:project) do
      projects.first
    end

    context "project doesn't exist" do
      before(:each) do
        allow(subject).to receive(:projects).and_return([])
      end

      it "raises an error message and doesn't write to the `projects.json` file" do
        expect(File).not_to(receive(:write))
        expect { subject.update_project!(project: project) }.to raise_error(RuntimeError, "Couldn't update project project-1 because it doesn't exists")
      end
    end

    context "project exists" do
      before(:each) do
        allow(subject).to receive(:projects).and_return(projects)
      end

      let(:updated_project_name) { "updated_project_name" }
      let(:updated_project) do
        FastlaneCI::Project.new(project_params.first.merge(project_name: updated_project_name))
      end

      it "updates the `project` name in the `projects.json` file" do
        expect { subject.update_project!(project: updated_project) }
          .to change { subject.projects.first.project_name }.from(first_project_name).to(updated_project_name)
      end
    end
  end

  describe "#delete_project!" do
    let(:project) do
      projects.first
    end

    context "project doesn't exist" do
      before(:each) do
        allow(subject).to receive(:projects).and_return([])
      end

      it "raises an error message and doesn't write to the `projects.json` file" do
        expect(File).not_to(receive(:write))
        expect { subject.delete_project!(project: project) }.to raise_error(RuntimeError)
      end
    end

    context "project exists" do
      before(:each) do
        allow(subject).to receive(:projects).and_return(projects)
      end

      it "removes the `project` from the `projects.json` file" do
        expect { subject.delete_project!(project: project) }.to change { subject.projects.size }.from(1).to(0)
      end
    end
  end

  private

  def new_project_name
    "new-project"
  end

  def new_project_params
    {
      name: new_project_name,
      repo_config: FastlaneCI::GitHubRepoConfig.new(
        git_url: "https://github.com/username/#{new_project_name}",
        description: "New Project",
        name: new_project_name,
        full_name: "username/#{new_project_name}"
      ),
      enabled: true,
      platform: "ios",
      lane: "default",
      artifact_provider: FastlaneCI::LocalArtifactProvider,
      job_triggers: []
    }
  end

  def first_project_name
    "project-1"
  end

  def project_params
    [
      {
        id: "b2be5614-b3a0-4aae-a70b-bf3b29a6ccac",
        repo_config: FastlaneCI::GitHubRepoConfig.new(
          git_url: "https://github.com/username/#{first_project_name}",
          description: "Project1",
          name: first_project_name,
          full_name: "username/#{first_project_name}"
        ),
        enabled: true,
        project_name: first_project_name,
        platform: "ios",
        lane: "default",
        artifact_provider: FastlaneCI::LocalArtifactProvider.new,
        job_triggers: []
      }
    ]
  end
end
