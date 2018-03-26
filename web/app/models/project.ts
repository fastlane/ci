export interface ProjectResponse {
  id: string;
  project_name: string;
}

export class Project {
  readonly name: string;

  constructor(project: ProjectResponse) {
    this.name = project.project_name;
  }
}
