import {mockRepositoryResponse} from '../common/test_helpers/mock_repository_data';

import {Repository} from '../models/repository';

describe('Repository Model', () => {
  it('should convert project response successfully', () => {
    const repository = new Repository(mockRepositoryResponse);

    expect(repository.fullName).toBe('fastlane/ci');
    expect(repository.url).toBe('https://github.com/fastlane/ci');
  });
});
