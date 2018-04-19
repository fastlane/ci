
import {Project} from '../../models/project';

import {mockBuildSummaryResponse_failure, mockBuildSummaryResponse_success} from './mock_build_response';

export const mockProject: Project = new Project({
  id: '12',
  name: 'the most coolest project',
  builds:
      [mockBuildSummaryResponse_success, mockBuildSummaryResponse_failure]
});
