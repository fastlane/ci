export interface RepositoryResponse {
  full_name: string;
  api_path: string;
  url: string;
}

export class Repository {
  readonly fullName: string;
  readonly apiPath: string;
  readonly url: string;

  constructor(repository: RepositoryResponse) {
    this.fullName = repository.full_name;
    this.apiPath = repository.api_path;
    this.url = repository.url;
  }
}
