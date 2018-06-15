import {Component, HostBinding, Input, OnInit} from '@angular/core';

import {BuildStatus} from '../../constants';

const FAILED_STATUSES: BuildStatus[] =
    [BuildStatus.FAILED, BuildStatus.MISSING_FASTFILE];

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
}
