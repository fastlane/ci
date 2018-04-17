import {BuildStatus, buildStatusToIcon, FastlaneStatus, fastlaneStatusToEnum} from '../common/constants';

export interface BuildSummaryResponse {
  number: number;
  status: FastlaneStatus;
  duration: number;
  sha: string;
  timestamp: string;
}

export class BuildSummary {
  readonly number: number;
  readonly status: BuildStatus;
  readonly duration: number;
  readonly sha: string;
  readonly date: Date;
  readonly statusIcon: string;

  constructor(buildSummary: BuildSummaryResponse) {
    this.number = buildSummary.number;
    this.duration = buildSummary.duration;
    this.sha = buildSummary.sha;
    this.status = fastlaneStatusToEnum(buildSummary.status);
    this.statusIcon = buildStatusToIcon(this.status);
    this.date = new Date(buildSummary.timestamp);
  }
}
