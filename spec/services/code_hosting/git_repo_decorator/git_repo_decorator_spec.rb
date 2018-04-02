require "spec_helper"
require "app/services/code_hosting/decorators/git_repo_decorator"

describe FastlaneCI::GitRepoDecorator do

  before(:each) do
    stub_file_io
    stub_git_repos
    stub_services

    class ClassThatReadsFromRepo
      include FastlaneCI::GitRepoDecorator

      def some_method_that_reads
        return "read"
      end
      pull_before(:some_method_that_reads, git_repo: FastlaneCI::GitRepo.new)
    end

    class ClassThatWritesToRepo
      include FastlaneCI::GitRepoDecorator

      def some_method_that_writes
        return "write"
      end
      commit_after(:some_method_that_writes, git_repo: FastlaneCI::GitRepo.new)
    end

    class ClassThatWritesAndReadsRepo
      include FastlaneCI::GitRepoDecorator

      class << self
        def git_repo
          @repo ||= FastlaneCI::GitRepo.new
        end
      end

      def some_method_that_writes_and_reads
        return "read and write"
      end
      pull_before(:some_method_that_writes_and_reads, git_repo: ClassThatWritesAndReadsRepo.git_repo)
      commit_after(:some_method_that_writes_and_reads, git_repo: ClassThatWritesAndReadsRepo.git_repo)
    end
  end

  let(:klass_reads) do
    return ClassThatReadsFromRepo.new
  end

  let(:klass_writes) do
    return ClassThatWritesToRepo.new
  end

  let(:klass_writes_and_reads) do
    return ClassThatWritesAndReadsRepo.new
  end

  describe "#pull_before" do
    it "calls `pull_before` before the actual method being called" do
      expect_any_instance_of(FastlaneCI::GitRepo).to receive(:pull)
      expect(klass_reads.some_method_that_reads).to eql("read")
    end

    it "calls the method even if the pull fails" do
      FastlaneCI::GitRepo.any_instance.stub(:pull).and_raise("boom")
      expect_any_instance_of(FastlaneCI::GitRepo).to receive(:pull)
      expect(klass_reads.some_method_that_reads).to eql("read")
    end
  end

  describe "#commit_after" do
    it "calls `commit_after` after the actual method being called" do
      expect_any_instance_of(FastlaneCI::GitRepo).to receive(:commit_changes!)
      expect_any_instance_of(FastlaneCI::GitRepo).to receive(:push)
      expect(klass_writes.some_method_that_writes).to eql("write")
    end

    it "calls the method even if the push fails" do
      FastlaneCI::GitRepo.any_instance.stub(:commit_changes!).and_raise("boom")
      expect_any_instance_of(FastlaneCI::GitRepo).to receive(:commit_changes!)
      expect(klass_writes.some_method_that_writes).to eql("write")
    end
  end

  describe "#pull_before and #commit_after" do
    it "calls `pull_before` before the method and `commit_after` after the method" do
      expect_any_instance_of(FastlaneCI::GitRepo).to receive(:pull)
      expect_any_instance_of(FastlaneCI::GitRepo).to receive(:commit_changes!)
      expect_any_instance_of(FastlaneCI::GitRepo).to receive(:push)
      expect(klass_writes_and_reads.some_method_that_writes_and_reads).to eql("read and write")
    end
  end
end
