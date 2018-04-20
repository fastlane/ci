import {BuildStatus} from '../common/constants';
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
});
