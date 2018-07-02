import {DOCUMENT} from '@angular/common';
import {ComponentFixture, TestBed} from '@angular/core/testing';
import {ReactiveFormsModule} from '@angular/forms';
import {MatButtonModule, MatStepperModule} from '@angular/material';
import {By} from '@angular/platform-browser';
import {BrowserAnimationsModule} from '@angular/platform-browser/animations';

import {OnboardComponent} from './onboard.component';

const FORM_CONTROL_IDS: string[] = ['encryptionKey'];

describe('OnboardComponent', () => {
  let fixture: ComponentFixture<OnboardComponent>;
  let document: jasmine.SpyObj<any>;
  let component: OnboardComponent;

  beforeEach(() => {
    document = {location: {origin: 'fake-host', href: 'fake-href'}};

    TestBed
        .configureTestingModule({
          imports: [
            MatStepperModule, BrowserAnimationsModule, MatButtonModule,
            ReactiveFormsModule
          ],
          declarations: [
            OnboardComponent,
          ],
        })
        .compileComponents();

    fixture = TestBed.createComponent(OnboardComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  for (const control_id of FORM_CONTROL_IDS) {
    it(`should have the ${control_id} control properly attached`, () => {
      const controlEl: HTMLInputElement =
          fixture.debugElement
              .query(By.css(`input[formcontrolname="${control_id}"]`))
              .nativeElement;

      controlEl.value = '10';
      controlEl.dispatchEvent(new Event('input'));
      fixture.detectChanges();

      expect(component.form.get(control_id).value).toBe('10');

      component.form.patchValue({[control_id]: '12'});
      fixture.detectChanges();

      expect(controlEl.value).toBe('12');
    });
  }

  it('should redirect to old onboarding when button is clicked', () => {
    spyOn(component, 'goToOldOnboarding');
    fixture.debugElement.query(By.css('.fci-onboard-welcome button'))
        .nativeElement.click();

    expect(component.goToOldOnboarding).toHaveBeenCalled();
  });
});
