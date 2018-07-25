import {DebugElement} from '@angular/core';
import {async, ComponentFixture, TestBed} from '@angular/core/testing';
import {MatTooltip, MatTooltipModule} from '@angular/material';
import {MatIconModule} from '@angular/material/icon';
import {By} from '@angular/platform-browser';
import {BrowserAnimationsModule} from '@angular/platform-browser/animations';

import {BuildStatus} from '../../constants';
import {getElement, getElementText} from '../../test_helpers/element_helper_functions';

import {StatusIconComponent} from './status-icon.component';

interface ExpectedIcon {
  iconString: string;
  class: string;
  tooltipString: string;
}

const EXPECTED_STATUSES = new Map<BuildStatus, ExpectedIcon>([
  [
    BuildStatus.SUCCESS, {
      iconString: 'check_circle',
      class: 'fci-status-icon-success',
      tooltipString: 'Success'
    }
  ],
  [
    BuildStatus.PENDING, {
      iconString: 'timelapse',
      class: 'fci-status-icon-pending',
      tooltipString: 'Pending'
    }
  ],
  [
    BuildStatus.RUNNING, {
      iconString: 'directions_run',
      class: 'fci-status-icon-running',
      tooltipString: 'Running'
    }
  ],
  [
    BuildStatus.FAILED, {
      iconString: 'cancel',
      class: 'fci-status-icon-failed',
      tooltipString: 'Failed'
    }
  ],
  [
    BuildStatus.INTERNAL_ISSUE, {
      iconString: 'warning',
      class: 'fci-status-icon-internal',
      tooltipString: 'Internal CI Issue'
    }
  ],
  [
    BuildStatus.MISSING_FASTFILE, {
      iconString: 'cancel',
      class: 'fci-status-icon-failed',
      tooltipString: 'Missing Fastfile'
    }
  ],
  [
    BuildStatus.INSTALLING_XCODE, {
      iconString: 'directions_run',
      class: 'fci-status-icon-running',
      tooltipString: 'Installing XCode'
    }
  ]
]);

describe('StatusIconComponent', () => {
  let component: StatusIconComponent;
  let fixture: ComponentFixture<StatusIconComponent>;
  let iconEl: DebugElement;

  beforeEach(async(() => {
    TestBed
        .configureTestingModule({
          imports: [MatIconModule, MatTooltipModule, BrowserAnimationsModule],
          declarations: [StatusIconComponent]
        })
        .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(StatusIconComponent);
    component = fixture.componentInstance;
    iconEl = fixture.debugElement;
    expect(component.status).toBeUndefined();
  });

  EXPECTED_STATUSES.forEach((expectedIcon, status) => {
    describe(`${status} status`, () => {
      it('should have expected icon and class', () => {
        component.status = status;
        fixture.detectChanges();

        const icon = getElement(iconEl, '.mat-icon');
        expect(getElementText(icon)).toBe(expectedIcon.iconString);
        expect(icon.nativeElement.classList).toContain(expectedIcon.class);
      });

      it('should have expected tooltip String', () => {
        component.status = status;
        fixture.detectChanges();

        const icon = getElement(iconEl, '.mat-icon');
        const tooltipDir: MatTooltip =
            icon.injector.get<MatTooltip>(MatTooltip);

        expect(tooltipDir.message).toBe(expectedIcon.tooltipString);
      });
    });
  });
});
