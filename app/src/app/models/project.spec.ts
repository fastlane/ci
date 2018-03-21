import {Project} from './project';
import {mockProjectResponse} from './test_helpers/mock_project_response';

describe('Project Model', () => {
  it('should convert project response successfully', () => {
    const project = new Project(mockProjectResponse);

    expect(project.name).toBe('the coolest project');
  });
});
