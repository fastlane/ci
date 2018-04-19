import {async, ComponentFixture, TestBed} from '@angular/core/testing';
import {MatIconModule} from '@angular/material/icon';
import {BuildStatus} from '../../constants';
import {StatusIconComponent} from './status-icon.component';

interface ExpectedIcon {
  iconString: string;
  class: string;
}

const EXPECTED_STATUSES = new Map<BuildStatus, ExpectedIcon>([
  [
    BuildStatus.SUCCESS,
    {iconString: 'sentiment_very_satisfied', class: 'fci-status-icon-success'}
  ],
  [
    BuildStatus.PENDING,
    {iconString: 'sentiment_neutral', class: 'fci-status-icon-pending'}
  ],
  [
    BuildStatus.FAILED, {
      iconString: 'sentiment_very_dissatisfied',
      class: 'fci-status-icon-failed'
    }
  ],
  [
    BuildStatus.INTERNAL_ISSUE, {
      iconString: 'sentiment_very_dissatisfied',
      class: 'fci-status-icon-failed'
    }
  ],
  [
    BuildStatus.MISSING_FASTFILE, {
      iconString: 'sentiment_very_dissatisfied',
      class: 'fci-status-icon-failed'
    }
  ],
  [
    undefined,
    {iconString: 'sentiment_satisfied', class: 'fci-status-icon-default'}
  ]
]);

describe('StatusIconComponent', () => {
  let component: StatusIconComponent;
  let fixture: ComponentFixture<StatusIconComponent>;
  let iconEl: HTMLElement;

  beforeEach(async(() => {
    TestBed
        .configureTestingModule(
            {imports: [MatIconModule], declarations: [StatusIconComponent]})
        .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(StatusIconComponent);
    component = fixture.componentInstance;
    iconEl = fixture.nativeElement;
    expect(component.status).toBeUndefined();
  });

  EXPECTED_STATUSES.forEach((expectedIcon, status) => {
    it(`should have expect icon and class when status is ${status}`, () => {
      component.status = status;
      fixture.detectChanges();

      const icon = iconEl.querySelector('.mat-icon');
      expect(icon.textContent.trim()).toBe(expectedIcon.iconString);
      expect(icon.classList).toContain(expectedIcon.class);
    });
  });
});
