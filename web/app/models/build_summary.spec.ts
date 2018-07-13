import {BuildStatus, FastlaneStatus} from '../common/constants';
import {mockBuildSummaryResponse_success} from '../common/test_helpers/mock_build_data';

import {BuildSummary} from './build_summary';

describe('Build Summary Model', () => {
  it('should convert build summary response successfully', () => {
    const build = new BuildSummary(mockBuildSummaryResponse_success);

    expect(build.number).toBe(2);
    expect(build.status).toBe(BuildStatus.SUCCESS);
    expect(build.duration).toBe(221234);
    expect(build.sha).toBe('asdfshzdggfdhdfh4');
    expect(build.shortSha).toBe('asdfsh');
    expect(build.date.getTime())
        .toBe(1522883518000);  // 2018-04-04 16:11:58 -0700
  });

  describe('#isFailure', () => {
    const FAILED_STATUSES: FastlaneStatus[] =
        ['failure', 'missing_fastfile', 'ci_problem'];

    for (const status of FAILED_STATUSES) {
      it(`should be true for status: ${status}`, () => {
        const summaryResponse =
            Object.assign({}, mockBuildSummaryResponse_success);
        summaryResponse.status = status;

        const build = new BuildSummary(summaryResponse);

        expect(build.isFailure()).toBe(true);
      });
    }

    it(`should be false for success status`, () => {
      const build = new BuildSummary(mockBuildSummaryResponse_success);

      expect(build.isFailure()).toBe(false);
    });
  });
});
