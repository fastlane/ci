import {Repository, RepositoryResponse} from '../../models/repository';

export const mockRepositoryResponse: RepositoryResponse = {
  full_name: 'fastlane/ci',
  api_path: 'https://api.github.com/fastlane/ci',
  url: 'https://github.com/fastlane/ci'
};

export const mockRepositoryListResponse: RepositoryResponse[] = [
  {
    full_name: 'fastlane/ci',
    api_path: 'https://api.github.com/fastlane/ci',
    url: 'https://github.com/fastlane/ci'
  },
  {
    full_name: 'fastlane/fastlane',
    api_path: 'https://api.github.com/fastlane/fastlane',
    url: 'https://github.com/fastlane/fastlane'
  },
  {
    full_name: 'fastlane/onboarding',
    api_path: 'https://api.github.com/fastlane/onboarding',
    url: 'https://github.com/fastlane/onboarding'
  },
];

export const mockRepositoryList =
mockRepositoryListResponse.map((response) => new Repository(response));
export const mockProjectResponse: RepositoryResponse = {
  full_name: 'fastlane/ci',
  api_path: 'https://api.github.com/fastlane/ci',
  url: 'https://github.com/fastlane/ci'
};

export const mockRepository = new Repository(mockProjectResponse);
