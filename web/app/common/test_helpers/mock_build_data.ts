import {Build, BuildArtifactResponse, BuildResponse} from '../../models/build';
import {BuildSummary, BuildSummaryResponse} from '../../models/build_summary';

// TODO: move all these mocks to common/ since they're being re-used.
export const mockBuildSummaryResponse_failure: BuildSummaryResponse = {
  number: 1,
  status: 'failure',
  duration: 1234,
  sha: 'cjsh4',
  branch: 'master',
  link_to_sha:
      'https://github.com/fastlane/ci/commit/1015c506762b1396a5d63fff6fe0f1de43c8de80',
  timestamp: '2018-04-04 16:11:58 -0700'
};

export const mockBuildSummaryResponse_success: BuildSummaryResponse = {
  number: 2,
  status: 'success',
  duration: 221234,
  branch: 'master',
  sha: 'asdfshzdggfdhdfh4',
  link_to_sha:
      'https://github.com/fastlane/ci/commit/1015c506762b1396a5d63fff6fe0f1de43c8de80',
  timestamp: '2018-04-04 16:11:58 -0700'
};

export const mockBuildArtifactResponse_log: BuildArtifactResponse = {
  id: '12345',
  type: 'fastlane.log'
};

export const mockBuildResponse: BuildResponse = {
  project_id: 'a32ef71e-368c-4091-9344-7fdc8c1ff390',
  number: 3,
  status: 'ci_problem',
  timestamp: '2018-04-04 16:11:58 -0700',
  duration: 120,
  description:
      'fastlane.ci encountered an error, check fastlane.ci logs for more information',
  trigger: 'commit',
  lane: 'test',
  platform: 'ios',
  parameters: null,
  build_tools: {'xcode_version': '9.1'},
  branch: 'test-branch',
  clone_url: 'https://github.com/nakhbari/HelloWorld.git',
  ref: 'pull/1/head',
  sha: '5903a0a7d2238846218c08ad9d5e278db7cf46c7',
  artifacts: [mockBuildArtifactResponse_log, {id: '54321', type: 'hack.exe'}]
};

export const mockBuild: Build = new Build(mockBuildResponse);

export const mockBuildSummary_success =
    new BuildSummary(mockBuildSummaryResponse_success);
