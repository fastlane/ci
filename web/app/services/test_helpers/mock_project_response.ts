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
];
