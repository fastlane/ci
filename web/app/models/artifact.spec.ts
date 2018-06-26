import {mockBuildArtifactResponse_log} from '../common/test_helpers/mock_build_data';

import {Artifact} from './artifact';

describe('Artifact Model', () => {
  it('should convert build artifact successfully', () => {
    const artifact = new Artifact(mockBuildArtifactResponse_log);

    expect(artifact.id).toBe('12345');
    expect(artifact.name).toBe('fastlane.log');
  });
});
