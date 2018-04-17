import {BuildSummaryResponse} from '../build_summary';

// TODO: move all these mocks to common/ since they're being re-used.
export const mockBuildSummaryResponse_failure: BuildSummaryResponse = {
  number: 1,
  status: 'failure',
  duration: 1234,
  sha: 'cjsh4',
  timestamp: '2018-04-04 16:11:58 -0700'
};

export const mockBuildSummaryResponse_success: BuildSummaryResponse = {
  number: 2,
  status: 'success',
  duration: 221234,
  sha: 'asdfsh4',
  timestamp: '2018-04-04 16:11:58 -0700'
};
