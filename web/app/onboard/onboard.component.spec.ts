import {DOCUMENT} from '@angular/common';
import {DebugElement} from '@angular/core';
import {ComponentFixture, TestBed} from '@angular/core/testing';
import {ReactiveFormsModule} from '@angular/forms';
import {MatButtonModule, MatIconModule, MatProgressSpinnerModule, MatStepperModule} from '@angular/material';
import {By} from '@angular/platform-browser';
import {BrowserAnimationsModule} from '@angular/platform-browser/animations';
import {Subject} from 'rxjs/Subject';

import {expectElementNotToExist, expectElementToExist, getElement, getElementText} from '../common/test_helpers/element_helper_functions';
import {UserDetails} from '../common/types';
import {DataService} from '../services/data.service';

import {OnboardComponent} from './onboard.component';

const FORM_CONTROL_IDS: string[] = ['encryptionKey', 'botToken', 'botPassword'];
const FORTY_CHAR_STRING: string = new Array(40 + 1).join('a');
const THIRY_NINE_CHAR_STRING: string = new Array(39 + 1).join('a');

describe('OnboardComponent', () => {
  let fixture: ComponentFixture<OnboardComponent>;
  let fixtureEl: DebugElement;
  let component: OnboardComponent;
  let dataService: jasmine.SpyObj<Partial<DataService>>;
  let userDetailsSubject: Subject<UserDetails>;

  beforeEach(() => {
    userDetailsSubject = new Subject<UserDetails>();
    dataService = {
      getUserDetails:
          jasmine.createSpy().and.returnValue(userDetailsSubject.asObservable())
    };

    TestBed
        .configureTestingModule({
          imports: [
            MatStepperModule, BrowserAnimationsModule, MatButtonModule,
            ReactiveFormsModule, MatProgressSpinnerModule, MatIconModule
          ],
          declarations: [
            OnboardComponent,
          ],
          providers: [
            {provide: DataService, useValue: dataService},
          ]
        })
        .compileComponents();

    fixture = TestBed.createComponent(OnboardComponent);
    fixtureEl = fixture.debugElement;
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  describe('Unit tests', () => {
    it('should not get user details when the bot token is 39 chars', () => {
      component.form.patchValue({botToken: THIRY_NINE_CHAR_STRING});

      expect(dataService.getUserDetails).not.toHaveBeenCalled();
    });

    it('should get user details when the bot token is 40 chars', () => {
      component.form.patchValue({botToken: FORTY_CHAR_STRING});

      expect(dataService.getUserDetails)
          .toHaveBeenCalledWith(FORTY_CHAR_STRING);
    });

    it('should clear email if the token is changed', () => {
      component.botEmail = 'fake@email.com';
      component.form.patchValue({botToken: 'new value'});

      expect(component.botEmail).toBeUndefined();
    });

    it('should set email from user details request', () => {
      component.form.patchValue({botToken: FORTY_CHAR_STRING});
      userDetailsSubject.next({github: {email: 'best@gmail.com'}});

      expect(component.botEmail).toBe('best@gmail.com');
    });

    it('should set isFetchingBotEmail to false after getting user details',
       () => {
         component.form.patchValue({botToken: FORTY_CHAR_STRING});
         expect(component.isFetchingBotEmail).toBe(true);

         userDetailsSubject.next({github: {email: 'best@gmail.com'}});

         expect(component.isFetchingBotEmail).toBe(false);
       });
  });

  describe('Shallow tests', () => {
    let tokenInputEl: HTMLInputElement;

    beforeEach(() => {
      component.botEmail = 'fake@email.com';
      fixture.detectChanges();

      tokenInputEl = getElement(fixtureEl, 'input[formcontrolname="botToken"]')
                         .nativeElement;
    });

    for (const control_id of FORM_CONTROL_IDS) {
      it(`should have the ${control_id} control properly attached`, () => {
        const controlEl: HTMLInputElement =
            getElement(fixtureEl, `input[formcontrolname="${control_id}"]`)
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

    it('should show success check mark if bot email exists', () => {
      expect(component.botEmail).toBeDefined();
      expectElementToExist(fixtureEl, '.fci-input-status .fci-success-icon');
    });

    it('should hide bot email and password if token changes', () => {
      expectElementToExist(fixtureEl, 'input[formcontrolname="botPassword"]');
      expect(getElementText(fixtureEl, '.fci-username')).toBe('fake@email.com');

      tokenInputEl.value = FORTY_CHAR_STRING;
      tokenInputEl.dispatchEvent(new Event('input'));
      fixture.detectChanges();

      expectElementNotToExist(
          fixtureEl, 'input[formcontrolname="botPassword"]');
      expectElementNotToExist(fixtureEl, '.fci-username');
    });

    it('should show spinner when looking for bot email', () => {
      expectElementNotToExist(fixtureEl, '.fci-input-status .mat-spinner');
      tokenInputEl.value = FORTY_CHAR_STRING;
      tokenInputEl.dispatchEvent(new Event('input'));
      fixture.detectChanges();

      expectElementToExist(fixtureEl, '.fci-input-status .mat-spinner');
    });

    it('should redirect to old onboarding when button is clicked', () => {
      spyOn(component, 'goToOldOnboarding');
      getElement(fixtureEl, '.fci-onboard-welcome button')
          .nativeElement.click();

      expect(component.goToOldOnboarding).toHaveBeenCalled();
    });
  });
});
