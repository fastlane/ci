import {ProjectSummary} from '../../models/project_summary';

export const mockProjectSummaryList: ProjectSummary[] = [
  new ProjectSummary({
    id: '1',
    name: 'the coolest project',
    latest_status: 'success',
    lane: 'ios test',
    latest_timestamp: '2018-04-04 16:11:58 -0700'
  }),
  new ProjectSummary({
    id: '2',
    name: 'this project is okay',
    latest_status: 'success',
    lane: 'ios release',
    latest_timestamp: '2018-04-04 16:11:58 -0700'
  }),
  new ProjectSummary({
    id: '3',
    name: 'this project needs some work',
    latest_status: 'failure',
    lane: 'ios test',
    latest_timestamp: '2018-04-04 16:11:58 -0700'
  }),
  new ProjectSummary({
    id: '4',
    name: 'this project needs some work',
    latest_status: null,
    lane: 'ios test',
    latest_timestamp: null
  }),
];
