import {DOCUMENT} from '@angular/common';
import {ComponentFixture, TestBed} from '@angular/core/testing';
import {MatButtonModule, MatStepperModule} from '@angular/material';
import {By} from '@angular/platform-browser';

import {OnboardComponent} from './onboard.component';

describe('OnboardComponent', () => {
  let fixture: ComponentFixture<OnboardComponent>;
  let document: jasmine.SpyObj<any>;
  let component: OnboardComponent;

  beforeEach(() => {
    document = {location: {origin: 'fake-host', href: 'fake-href'}};

    TestBed
        .configureTestingModule({
          imports: [MatStepperModule, MatButtonModule],
          declarations: [
            OnboardComponent,
          ],
        })
        .compileComponents();

    fixture = TestBed.createComponent(OnboardComponent);
    component = fixture.componentInstance;
  });

  it('should redirect to old onboarding when button is clicked', () => {
    spyOn(component, 'goToOldOnboarding');
    fixture.debugElement.query(By.css('.fci-onboard-welcome button'))
        .nativeElement.click();

    expect(component.goToOldOnboarding).toHaveBeenCalled();
  });
});
