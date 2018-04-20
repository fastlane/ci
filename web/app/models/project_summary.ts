import {BuildStatus, buildStatusToIcon, FastlaneStatus, fastlaneStatusToEnum} from '../common/constants';

export interface ProjectSummaryResponse {
  id: string;
  name: string;
  lane: string;
  repo_name: string;
  latest_status?: FastlaneStatus;
  latest_timestamp?: string;
}

export class ProjectSummary {
  readonly name: string;
  readonly id: string;
  readonly lane: string;
  readonly repoName: string;
  readonly latestStatus?: BuildStatus;
  readonly latestDate?: Date;
  readonly statusIcon: string;

  constructor(projectSummary: ProjectSummaryResponse) {
    this.name = projectSummary.name;
    this.id = projectSummary.id;
    this.lane = projectSummary.lane;
    this.repoName = projectSummary.repo_name;
    this.latestStatus = projectSummary.latest_status ?
        fastlaneStatusToEnum(projectSummary.latest_status) :
        undefined;
    this.statusIcon = buildStatusToIcon(this.latestStatus);
    this.latestDate = projectSummary.latest_timestamp ?
        new Date(projectSummary.latest_timestamp) :
        undefined;
  }
}
