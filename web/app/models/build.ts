import {BuildStatus, FastlaneStatus, fastlaneStatusToEnum} from '../common/constants';
import {Artifact} from './artifact';

const SHORT_SHA_LENGTH = 6;
const FINAL_STATES: Set<BuildStatus> = new Set([
  BuildStatus.FAILED, BuildStatus.INTERNAL_ISSUE, BuildStatus.MISSING_FASTFILE,
  BuildStatus.SUCCESS
]);

export interface BuildLogLine {
  message: string;
}

export interface BuildArtifactResponse {
  id: string;
  type: string;
}

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
  artifacts: BuildArtifactResponse[];
}

export class Build {
  readonly number: number;
  readonly projectId: string;
  readonly status: BuildStatus;
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
  readonly artifacts: Artifact[];

  constructor(build: BuildResponse) {
    this.number = build.number;
    this.projectId = build.project_id;
    this.description = build.description;
    this.trigger = build.trigger;
    this.lane = build.lane;
    this.platform = build.platform;
    this.parameters = build.parameters;
    this.buildTools = build.build_tools;
    this.cloneUrl = build.clone_url;
    this.branch = build.branch;
    this.ref = build.ref;
    this.duration = build.duration;
    this.sha = build.sha;
    this.shortSha = this.sha.slice(0, SHORT_SHA_LENGTH);
    this.status = fastlaneStatusToEnum(build.status);
    this.date = new Date(build.timestamp);
    this.artifacts = build.artifacts.map((artifact) => new Artifact(artifact));
  }

  isComplete(): boolean {
    return FINAL_STATES.has(this.status);
  }
}
