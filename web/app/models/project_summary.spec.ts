import {BuildStatus} from '../common/constants';
import {mockProjectSummaryResponse} from '../common/test_helpers/mock_project_data';

import {ProjectSummary} from './project_summary';

describe('Project Summary Model', () => {
  it('should convert project response successfully', () => {
    const project = new ProjectSummary(mockProjectSummaryResponse);

    expect(project.id).toBe('1');
    expect(project.name).toBe('the coolest project');
    expect(project.latestStatus).toBe(BuildStatus.SUCCESS);
    expect(project.lane).toBe('ios test');
    expect(project.repoName).toBe('fastlane/TacoRocat');
    expect(project.latestDate.getTime())
        .toBe(1522883518000);  // 2018-04-04 16:11:58 -0700
  });

  // TODO: Move this into a test that tests the helper function
  it('should handle all statuses', () => {
    const response = Object.assign({}, mockProjectSummaryResponse);

    response.latest_status = 'success';
    expect(new ProjectSummary(response).latestStatus).toBe(BuildStatus.SUCCESS);
    response.latest_status = 'failure';
    expect(new ProjectSummary(response).latestStatus).toBe(BuildStatus.FAILED);
    response.latest_status = 'ci_problem';
    expect(new ProjectSummary(response).latestStatus)
        .toBe(BuildStatus.INTERNAL_ISSUE);
    response.latest_status = 'pending';
    expect(new ProjectSummary(response).latestStatus).toBe(BuildStatus.PENDING);
    response.latest_status = 'missing_fastfile';
    expect(new ProjectSummary(response).latestStatus)
        .toBe(BuildStatus.MISSING_FASTFILE);
  });
});
