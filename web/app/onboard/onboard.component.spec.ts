import {DOCUMENT} from '@angular/common';
import {DebugElement} from '@angular/core';
import {ComponentFixture, TestBed} from '@angular/core/testing';
import {ReactiveFormsModule} from '@angular/forms';
import {MatButtonModule, MatIconModule, MatProgressSpinnerModule, MatStepperModule} from '@angular/material';
import {By} from '@angular/platform-browser';
import {BrowserAnimationsModule} from '@angular/platform-browser/animations';
import {Subject} from 'rxjs/Subject';
// tslint:disable-next-line:max-line-length
import {expectElementNotToExist, expectElementToExist, expectInputControlToBeAttachedToForm, getAllElements, getElement, getElementText} from '../common/test_helpers/element_helper_functions';
import {UserDetails} from '../common/types';
import {ConfiguredSections} from '../models/configured_sections';
import {DataService} from '../services/data.service';

import {OnboardComponent} from './onboard.component';

describe('OnboardComponent', () => {
  let fixture: ComponentFixture<OnboardComponent>;
  let fixtureEl: DebugElement;
  let component: OnboardComponent;
  let dataService: jasmine.SpyObj<Partial<DataService>>;
  let configuredSectionsSubject: Subject<ConfiguredSections>;
  let encryptionKeySubject: Subject<void>;

  beforeEach(() => {
    configuredSectionsSubject = new Subject<ConfiguredSections>();
    encryptionKeySubject = new Subject<void>();
    dataService = {
      getServerConfiguredSections: jasmine.createSpy().and.returnValue(
          configuredSectionsSubject.asObservable()),
      setEncryptionKey: jasmine.createSpy().and.returnValue(
          encryptionKeySubject.asObservable())
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

  function expectStepIndexContentToBeShown(index: number) {
    const stepEl = getAllElements(fixtureEl, '.mat-step')[index];
    expectElementToExist(stepEl, '.mat-vertical-content-container');
  }

  it('should redirect to old onboarding when button is clicked', () => {
    spyOn(component, 'goToOldOnboarding');
    getElement(fixtureEl, '.fci-onboard-welcome button').nativeElement.click();

    expect(component.goToOldOnboarding).toHaveBeenCalled();
  });

  describe('Stepper', () => {
    it('should navigate to OAuth section if Encryption key is complete', () => {
      configuredSectionsSubject.next(new ConfiguredSections(
          {encryption_key: true, oauth: false, config_repo: false}));
      fixture.detectChanges();

      expectStepIndexContentToBeShown(1);
    });

    it('should navigate to Config Repo section if other sections are complete',
       () => {
         configuredSectionsSubject.next(new ConfiguredSections(
             {encryption_key: true, oauth: true, config_repo: false}));
         fixture.detectChanges();

         expectStepIndexContentToBeShown(2);
       });

    it('should not be able to click ahead to another step', () => {
      configuredSectionsSubject.next(new ConfiguredSections(
          {encryption_key: false, oauth: false, config_repo: false}));
      fixture.detectChanges();

      const secondStepEl = getAllElements(fixtureEl, '.mat-step')[1];
      getElement(secondStepEl, '.mat-step-header').nativeElement.click();

      // still on first step
      expectStepIndexContentToBeShown(0);
    });

    it('should not be able to click back on completed step', () => {
      configuredSectionsSubject.next(new ConfiguredSections(
          {encryption_key: true, oauth: false, config_repo: false}));
      fixture.detectChanges();

      const firstStepEl = getAllElements(fixtureEl, '.mat-step')[0];
      getElement(firstStepEl, '.mat-step-header').nativeElement.click();

      // still on second step
      expectStepIndexContentToBeShown(1);
    });
  });

  describe('Encryption Key Section', () => {
    let submitButtonEl: HTMLButtonElement;

    beforeEach(() => {
      configuredSectionsSubject.next(new ConfiguredSections(
          {encryption_key: false, oauth: false, config_repo: false}));
      fixture.detectChanges();

      submitButtonEl =
          getElement(
              fixtureEl, '.fci-step-button-container button[type="submit"]')
              .nativeElement;
    });

    function submitEncryptionKey() {
      component.encryptionKeyForm.patchValue({encryptionKey: 'some-key'});
      fixture.detectChanges();  // enable submit button

      submitButtonEl.click();
      fixture.detectChanges();
    }

    it('should have the key control properly attached', () => {
      expectInputControlToBeAttachedToForm(
          fixture, 'encryptionKey', component.encryptionKeyForm);
    });

    it('should show spinner when saving encryption key', () => {
      expectElementNotToExist(
          fixtureEl, '.fci-step-button-container .mat-spinner');
      submitEncryptionKey();

      expectElementToExist(
          fixtureEl, '.fci-step-button-container .mat-spinner');
    });

    it('should stop showing spinner saving encryption key is complete', () => {
      submitEncryptionKey();
      expectElementToExist(
          fixtureEl, '.fci-step-button-container .mat-spinner');

      encryptionKeySubject.next();
      fixture.detectChanges();

      expectElementNotToExist(
          fixtureEl, '.fci-step-button-container .mat-spinner');
    });

    it('should have submit button disabled when form is invalid', () => {
      expect(component.encryptionKeyForm.valid).toBe(false);
      expect(submitButtonEl.disabled).toBe(true);
    });

    it('should have submit button enabled when form is valid', () => {
      component.encryptionKeyForm.patchValue({encryptionKey: 'key'});
      fixture.detectChanges();

      expect(component.encryptionKeyForm.valid).toBe(true);
      expect(submitButtonEl.disabled).toBe(false);
    });

    it('should navigate to OAuth when encryption has just been set', () => {
      submitEncryptionKey();
      encryptionKeySubject.next();
      fixture.detectChanges();

      expectStepIndexContentToBeShown(1);
    });

    it('should navigate to Config Repo section when OAuth is set, and encryption has just been set',
       () => {
         configuredSectionsSubject.next(new ConfiguredSections(
             {encryption_key: false, oauth: true, config_repo: false}));
         fixture.detectChanges();
         submitEncryptionKey();
         encryptionKeySubject.next();
         fixture.detectChanges();

         expectStepIndexContentToBeShown(2);
       });
  });
});
