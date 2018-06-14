import {BuildStatus, FastlaneStatus, fastlaneStatusToEnum} from '../common/constants';

const SHORT_SHA_LENGTH = 6;

export interface BuildResponse {
  number: number;
  project_id: string;
  status: FastlaneStatus;
  duration: number;
  description: string;
  trigger: string;
  lane: string;
  platform: string;
  parameters: {[param: string]: string};
  build_tools: {[tool: string]: string};
  clone_url: string;
  branch: string;
  ref: string;
  sha: string;
  timestamp: string;
}

export class Build {
  readonly number: number;
  readonly projectId: string;
  readonly status: FastlaneStatus;
  readonly duration: number;
  readonly description: string;
  readonly trigger: string;
  readonly lane: string;
  readonly platform: string;
  readonly parameters: {[param: string]: string};
  readonly buildTools: {[tool: string]: string};
  readonly cloneUrl: string;
  readonly branch: string;
  readonly ref: string;
  readonly sha: string;
  readonly shortSha: string;
  readonly date: Date;

  constructor(buildSummary: BuildResponse) {
    this.number = buildSummary.number;
    this.projectId = buildSummary.project_id;
    this.description = buildSummary.description;
    this.trigger = buildSummary.trigger;
    this.lane = buildSummary.lane;
    this.platform = buildSummary.platform;
    this.parameters = buildSummary.parameters;
    this.buildTools = buildSummary.build_tools;
    this.cloneUrl = buildSummary.clone_url;
    this.branch = buildSummary.branch;
    this.ref = buildSummary.ref;
    this.duration = buildSummary.duration;
    this.sha = buildSummary.sha;
    this.shortSha = this.sha.slice(0, SHORT_SHA_LENGTH);
    this.status = fastlaneStatusToEnum(buildSummary.status);
    this.date = new Date(buildSummary.timestamp);
  }
}
