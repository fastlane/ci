import {BuildStatus, FastlaneStatus, fastlaneStatusToEnum} from '../common/constants'

export interface ProjectSummaryResponse {
  id: string;
  name: string;
  lane: string;
  latest_status: FastlaneStatus;
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
    this.latestStatus = fastlaneStatusToEnum(projectSummary.latest_status);
    this.latestDate = new Date(projectSummary.latest_timestamp);
  }
}
