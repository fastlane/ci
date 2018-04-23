export interface RepositoryResponse {
  full_name: string;
  url: string;
}

export class Repository {
  readonly fullName: string;
  readonly url: string;

  constructor(repository: RepositoryResponse) {
    this.fullName = repository.full_name;
    this.url = repository.url;
  }
}
