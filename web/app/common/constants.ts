export enum BuildStatus {
  SUCCESS = 'success',
  FAILED = 'failure',
  PENDING = 'pending',
  MISSING_FASTFILE = 'missing_fastfile',
  INTERNAL_ISSUE = 'ci_problem'
}

export type FastlaneStatus =
    'failure'|'success'|'ci_problem'|'pending'|'missing_fastfile';

export function fastlaneStatusToEnum(status?: FastlaneStatus): BuildStatus | undefined {
  if (status) {
    switch (status) {
      case 'success':
        return BuildStatus.SUCCESS;
      case 'failure':
        return BuildStatus.FAILED;
      case 'pending':
        return BuildStatus.PENDING;
      case 'missing_fastfile':
        return BuildStatus.MISSING_FASTFILE;
      case 'ci_problem':
        return BuildStatus.INTERNAL_ISSUE;
      default:
        throw new Error(`Unknown status type ${status}`);
    }
  } else {
    return undefined; 
  }
}

export function buildStatusToIcon(status?: BuildStatus) {
  if (status) {
    switch (status) {
      case BuildStatus.SUCCESS:
        return 'done';
      case BuildStatus.PENDING:
        return 'pause_circle_filled';
      case BuildStatus.FAILED:
      case BuildStatus.MISSING_FASTFILE:
        return 'error';
      case BuildStatus.INTERNAL_ISSUE:
        return 'warning';
      default:
        throw new Error(`Unknown build status ${status}`);
    }
  } else {
    return 'pause_circle_filled';
  }
}
