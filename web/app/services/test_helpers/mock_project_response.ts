import {timestamp} from 'rxjs/operators/timestamp';

import {BuildSummary, BuildSummaryResponse} from '../../models/build_summary';
import {ProjectResponse} from '../../models/project';
import {ProjectSummaryResponse} from '../../models/project_summary';

export const mockProjectListResponse: ProjectSummaryResponse[] = [
  {
    id: '1',
    name: 'the coolest project',
    latest_status: 'success',
    lane: 'ios test',
    latest_timestamp: '2018-04-04 16:11:58 -0700'
  },
  {
    id: '2',
    name: 'this project is okay',
    latest_status: 'success',
    lane: 'ios release',
    latest_timestamp: '2018-04-04 16:11:58 -0700'
  },
  {
    id: '3',
    name: 'this project needs some work',
    latest_status: 'failure',
    lane: 'ios test',
    latest_timestamp: '2018-04-04 16:11:58 -0700'
  },
  {
    id: '4',
    name: 'this project needs some work',
    latest_status: null,
    lane: 'ios test',
    latest_timestamp: null
  },
];

const mockBuildSummaryResponse_failure: BuildSummaryResponse = {
  number: 1,
  status: 'failure',
  duration: 1234,
  sha: 'cjsh4',
  timestamp: '2018-04-04 16:11:58 -0700'
};

const mockBuildSummaryResponse_success: BuildSummaryResponse = {
  number: 2,
  status: 'success',
  duration: 221234,
  sha: 'asdfsh4',
  timestamp: '2018-04-04 16:11:58 -0700'
};

export const mockProjectResponse: ProjectResponse = {
  id: '12',
  name: 'the most coolest project',
  builds: [mockBuildSummaryResponse_success, mockBuildSummaryResponse_failure]
};
