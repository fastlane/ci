import {BuildStatus} from '../common/constants';
import {mockProjectResponse} from '../common/test_helpers/mock_project_data';

import {Project} from './project';

describe('Project Model', () => {
  it('should convert project response successfully', () => {
    const project = new Project(mockProjectResponse);

    expect(project.id).toBe('12');
    expect(project.name).toBe('the most coolest project');
    expect(project.builds.length).toBe(2);
    expect(project.builds[0].status).toBe(BuildStatus.SUCCESS);
    expect(project.builds[1].status).toBe(BuildStatus.FAILED);
  });

  it('should get last failed build', () => {
    const project = new Project(mockProjectResponse);

    expect(project.lastFailedBuild().number).toBe(1);
  });

  it('should get last successful build', () => {
    const project = new Project(mockProjectResponse);

    expect(project.lastSuccessfulBuild().number).toBe(2);
  });
});
