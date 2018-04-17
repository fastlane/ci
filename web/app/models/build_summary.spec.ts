import {BuildStatus} from '../common/constants';
import {BuildSummary} from './build_summary';
import {mockBuildSummaryResponse_success} from './test_helpers/mock_build_response';

describe('Build Summary Model', () => {
  it('should convert build summary response successfully', () => {
    const build = new BuildSummary(mockBuildSummaryResponse_success);

    expect(build.number).toBe(2);
    expect(build.status).toBe(BuildStatus.SUCCESS);
    expect(build.duration).toBe(221234);
    expect(build.sha).toBe('asdfsh4');
    expect(build.date.getTime())
        .toBe(1522883518000);  // 2018-04-04 16:11:58 -0700
  });
});
