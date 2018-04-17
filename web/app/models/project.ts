import {BuildSummary, BuildSummaryResponse} from './build_summary';

export interface ProjectResponse {
  id: string;
  name: string;
  builds: BuildSummaryResponse[];
}

export class Project {
  readonly name: string;
  readonly id: string;
  readonly builds: BuildSummary[];

  constructor(project: ProjectResponse) {
    this.name = project.name;
    this.id = project.id;
    this.builds = project.builds.map((build) => new BuildSummary(build));
  }
}
