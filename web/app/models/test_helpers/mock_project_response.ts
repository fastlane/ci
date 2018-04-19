import {ProjectResponse} from '../project';
import {ProjectSummaryResponse} from '../project_summary';

import {mockBuildSummaryResponse_failure, mockBuildSummaryResponse_success} from './mock_build_response';

export const mockProjectSummaryResponse: ProjectSummaryResponse = {
  id: '1',
  name: 'the coolest project',
  latest_status: 'success',
  lane: 'ios test',
  latest_timestamp: '2018-04-04 16:11:58 -0700'
};


export const mockProjectResponse: ProjectResponse = {
  id: '12',
  name: 'the most coolest project',
  builds: [mockBuildSummaryResponse_success, mockBuildSummaryResponse_failure]
};
