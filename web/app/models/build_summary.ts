import {BuildStatus, FastlaneStatus, fastlaneStatusToEnum} from '../common/constants';

const SHORT_SHA_LENGTH = 6;

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
  readonly shortSha: string;
  readonly date: Date;

  constructor(buildSummary: BuildSummaryResponse) {
    this.number = buildSummary.number;
    this.duration = buildSummary.duration;
    this.sha = buildSummary.sha;
    this.shortSha = this.sha.slice(0, SHORT_SHA_LENGTH);
    this.status = fastlaneStatusToEnum(buildSummary.status);
    this.date = new Date(buildSummary.timestamp);
  }
}
