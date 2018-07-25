import {Component, HostBinding, Input, OnInit} from '@angular/core';

import {BuildStatus} from '../../constants';

const FAILED_STATUSES: BuildStatus[] =
    [BuildStatus.FAILED, BuildStatus.MISSING_FASTFILE];

const RUNNING_STATUSES: BuildStatus[] = [BuildStatus.INSTALLING_XCODE, BuildStatus.RUNNING];

@Component({
  selector: 'fci-status-icon',
  templateUrl: './status-icon.component.html',
  styleUrls: ['./status-icon.component.scss']
})
export class StatusIconComponent {
  @HostBinding('class') classes = ['fci-status-icon'];
  @Input() status: BuildStatus;
  readonly BuildStatus = BuildStatus;

  /**
   * Returns the status if it is a failed status, or false otherwise to skip the
   * ngSwitchCase.
   */
  isFailedState(): BuildStatus|false {
    return FAILED_STATUSES.includes(this.status) ? this.status : false;
  }

  isRunningState(): BuildStatus|false {
    return RUNNING_STATUSES.includes(this.status) ? this.status : false;
  }

  getTooltipString(): string {
    switch (this.status) {
      case BuildStatus.FAILED:
        return 'Failed';
      case BuildStatus.SUCCESS:
        return 'Success';
      case BuildStatus.MISSING_FASTFILE:
        return 'Missing Fastfile';
      case BuildStatus.INSTALLING_XCODE:
        return 'Installing XCode';
      case BuildStatus.INTERNAL_ISSUE:
        return 'Internal CI Issue';
      case BuildStatus.PENDING:
        return 'Pending';
      case BuildStatus.RUNNING:
        return 'Running';
      default:
        throw new Error(`Unknown status type ${this.status}`);
    }
  }
}
