import {BuildStatus} from '../common/constants';

import {BuildSummary, BuildSummaryResponse} from './build_summary';

export interface ProjectResponse {
  id: string;
  name: string;
  lane: string;
  repo_name: string;
  builds: BuildSummaryResponse[];
  environment_variables: {[key: string]: string};
}

export class Project {
  readonly name: string;
  readonly id: string;
  readonly repoName: string;
  readonly lane: string;
  readonly builds: BuildSummary[];
  readonly environmentVariables: {[key: string]: string};

  constructor(project: ProjectResponse) {
    this.name = project.name;
    this.id = project.id;
    this.repoName = project.repo_name;
    this.lane = project.lane;
    this.builds = project.builds.map((build) => new BuildSummary(build));
    this.environmentVariables = project.environment_variables;
  }

  lastSuccessfulBuild(): BuildSummary|null {
    return this.builds.find((build) => build.status === BuildStatus.SUCCESS) ||
        null;
  }

  lastFailedBuild(): BuildSummary|null {
    return this.builds.find((build) => build.isFailure()) || null;
  }
}
