export enum BuildStatus {
  SUCCESS = 'success',
  FAILED = 'failure',
  PENDING = 'pending',
  RUNNING = 'running',
  MISSING_FASTFILE = 'missing_fastfile',
  INTERNAL_ISSUE = 'ci_problem',
  INSTALLING_XCODE = 'installing_xcode'
}

export enum LocalStorageKeys {
  AUTH_TOKEN = 'auth_token'
}

export type FastlaneStatus = 'failure'|'success'|'ci_problem'|'pending'|'running'|
    'missing_fastfile'|'installing_xcode';

export function fastlaneStatusToEnum(status: FastlaneStatus): BuildStatus {
  switch (status) {
    case 'success':
      return BuildStatus.SUCCESS;
    case 'failure':
      return BuildStatus.FAILED;
    case 'pending':
      return BuildStatus.PENDING;
    case 'running':
      return BuildStatus.RUNNING;
    case 'missing_fastfile':
      return BuildStatus.MISSING_FASTFILE;
    case 'ci_problem':
      return BuildStatus.INTERNAL_ISSUE;
    case 'installing_xcode':
      return BuildStatus.INSTALLING_XCODE;
    default:
      throw new Error(`Unknown status type ${status}`);
  }
}

/**
 * This is what is defined by GitHub to be their token length, but it can be
 * modified.
 */
export const GITHUB_API_TOKEN_LENGTH = 40;
