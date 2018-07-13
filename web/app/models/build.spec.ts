import {BuildStatus, FastlaneStatus} from '../common/constants';
import {mockBuildResponse} from '../common/test_helpers/mock_build_data';

import {Build} from './build';

function getBuildWithStatus(status: FastlaneStatus): Build {
  const buildResponse = Object.assign({}, mockBuildResponse);
  buildResponse.status = status;

  return new Build(buildResponse);
}

describe('Build Model', () => {
  it('should convert build response successfully', () => {
    const build = new Build(mockBuildResponse);

    expect(build.number).toBe(3);
    expect(build.projectId).toBe('a32ef71e-368c-4091-9344-7fdc8c1ff390');
    expect(build.description)
        .toBe(
            'fastlane.ci encountered an error, check fastlane.ci logs for more information');
    expect(build.trigger).toBe('commit');
    expect(build.lane).toBe('test');
    expect(build.platform).toBe('ios');
    expect(build.status).toBe(BuildStatus.INTERNAL_ISSUE);
    expect(build.duration).toBe(120);
    expect(build.sha).toBe('5903a0a7d2238846218c08ad9d5e278db7cf46c7');
    expect(build.shortSha).toBe('5903a0');
    expect(build.date.getTime())
        .toBe(1522883518000);  // 2018-04-04 16:11:58 -0700
    expect(build.cloneUrl).toBe('https://github.com/nakhbari/HelloWorld.git');
    expect(build.branch).toBe('test-branch');
    expect(build.ref).toBe('pull/1/head');
    expect(build.buildTools).toEqual({'xcode_version': '9.1'});
    expect(build.artifacts.length).toBe(2);
    expect(build.artifacts[0].id).toBe('12345');
    expect(build.artifacts[1].name).toBe('hack.exe');

    // TODO: update this with real values once implemented on backend
    expect(build.parameters).toBe(null);
  });

  describe('#isComplete', () => {
    const COMPLETE_STATUSES: FastlaneStatus[] =
        ['failure', 'missing_fastfile', 'ci_problem', 'success'];
    const RUNNING_STATUSES: FastlaneStatus[] = ['pending', 'installing_xcode'];

    for (const status of COMPLETE_STATUSES) {
      it(`should be true for status: ${status}`, () => {
        expect(getBuildWithStatus(status).isComplete()).toBe(true);
      });
    }

    for (const status of RUNNING_STATUSES) {
      it(`should be false for status: ${status}`, () => {
        expect(getBuildWithStatus(status).isComplete()).toBe(false);
      });
    }
  });
});
