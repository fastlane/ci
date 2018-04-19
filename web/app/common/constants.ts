export enum BuildStatus {
  SUCCESS = 'success',
  FAILED = 'failure',
  PENDING = 'pending',
  MISSING_FASTFILE = 'missing_fastfile',
  INTERNAL_ISSUE = 'ci_problem'
}

export type FastlaneStatus =
    'failure'|'success'|'ci_problem'|'pending'|'missing_fastfile';

export function fastlaneStatusToEnum(status: FastlaneStatus): BuildStatus {
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
}
