import {Repository, RepositoryResponse} from '../../models/repository';

export const mockRepositoryResponse: RepositoryResponse = {
  full_name: 'fastlane/ci',
  url: 'https://github.com/fastlane/ci'
};

export const mockRepositoryListResponse: RepositoryResponse[] = [
  {
    full_name: 'fastlane/ci',
    url: 'https://github.com/fastlane/ci'
  },
  {
    full_name: 'fastlane/fastlane',
    url: 'https://github.com/fastlane/fastlane'
  },
  {
    full_name: 'fastlane/onboarding',
    url: 'https://github.com/fastlane/onboarding'
  },
];

export const mockRepositoryList =
mockRepositoryListResponse.map((response) => new Repository(response));
export const mockProjectResponse: RepositoryResponse = {
  full_name: 'fastlane/ci',
  url: 'https://github.com/fastlane/ci'
};

export const mockRepository = new Repository(mockProjectResponse);
