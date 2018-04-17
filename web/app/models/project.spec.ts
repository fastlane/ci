import {BuildStatus} from '../common/constants';
import {Project} from './project';
import {mockProjectResponse} from './test_helpers/mock_project_response';

describe('Project Model', () => {
  it('should convert project response successfully', () => {
    const project = new Project(mockProjectResponse);

    expect(project.id).toBe('12');
    expect(project.name).toBe('the most coolest project');
    expect(project.builds.length).toBe(2);
    expect(project.builds[0].status).toBe(BuildStatus.SUCCESS);
    expect(project.builds[1].status).toBe(BuildStatus.FAILED);
  });
});
