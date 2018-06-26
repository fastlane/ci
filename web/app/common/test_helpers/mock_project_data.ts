import {Project, ProjectResponse} from '../../models/project';
import {ProjectSummary, ProjectSummaryResponse} from '../../models/project_summary';

import {mockBuildSummaryResponse_failure, mockBuildSummaryResponse_success} from './mock_build_data';

export const mockProjectSummaryResponse: ProjectSummaryResponse = {
  id: '1',
  name: 'the coolest project',
  latest_status: 'success',
  repo_name: 'fastlane/TacoRocat',
  lane: 'ios test',
  latest_timestamp: '2018-04-04 16:11:58 -0700'
};

export const mockProjectListResponse: ProjectSummaryResponse[] = [
  {
    id: '1',
    name: 'the coolest project',
    latest_status: 'success',
    lane: 'ios test',
    repo_name: 'fastlane/TacoRocat',
    latest_timestamp: '2018-04-04 16:11:58 -0700'
  },
  {
    id: '2',
    name: 'this project is okay',
    latest_status: 'success',
    repo_name: 'fastlane/TacoRocat',
    lane: 'ios release',
    latest_timestamp: '2018-04-04 16:11:58 -0700'
  },
  {
    id: '3',
    name: 'this project needs some work',
    latest_status: 'failure',
    repo_name: 'fastlane/TacoRocat',
    lane: 'ios test',
    latest_timestamp: '2018-04-04 16:11:58 -0700'
  },
  {
    id: '4',
    name: 'this project needs some work',
    latest_status: undefined,
    repo_name: 'fastlane/TacoRocat',
    lane: 'ios test',
    latest_timestamp: undefined
  },
];

export const mockProjectSummaryList =
    mockProjectListResponse.map((response) => new ProjectSummary(response));

export const mockProjectSummary =
    new ProjectSummary(mockProjectSummaryResponse);

export const mockProjectResponse: ProjectResponse = {
  id: '12',
  repo_name: 'fastlane/TacoRocat',
  lane: 'ios test',
  name: 'the most coolest project',
  builds: [mockBuildSummaryResponse_success, mockBuildSummaryResponse_failure]
};

export const getMockProject = () => new Project(mockProjectResponse);
