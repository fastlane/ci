import {BuildStatus} from '../common/constants'

export interface ProjectSummaryResponse {
  id: string;
  name: string;
  lane: string;
  latest_status: 'failure'|'success'|'ci_problem'|'pending'|'missing_fastfile';
  latest_timestamp: string;
}

export class ProjectSummary {
  readonly name: string;
  readonly id: string;
  readonly lane: string;
  readonly latestStatus: BuildStatus;
  readonly latestDate: Date;

  constructor(projectSummary: ProjectSummaryResponse) {
    this.name = projectSummary.name;
    this.id = projectSummary.id;
    this.lane = projectSummary.lane;
    this.latestStatus = BuildStatus[projectSummary.latest_status];
    this.latestDate = new Date(projectSummary.latest_timestamp);
  }
}
