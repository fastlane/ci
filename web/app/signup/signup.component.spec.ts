import {DebugElement} from '@angular/core';
import {async, ComponentFixture, TestBed} from '@angular/core/testing';
import {FormsModule, ReactiveFormsModule} from '@angular/forms';
import {MatButtonModule} from '@angular/material';
import {By} from '@angular/platform-browser';
import {Router} from '@angular/router';
import {Subject} from 'rxjs/Subject';

import {expectInputControlToBeAttachedToForm, getElement, getElementText} from '../common/test_helpers/element_helper_functions';
import {UserDetails} from '../common/types';
import {AuthService} from '../services/auth.service';
import {DataService} from '../services/data.service';

import {SignupComponent} from './signup.component';

const FORM_CONTROL_IDS: string[] = ['token', 'password'];

describe('SignupComponent', () => {
  let component: SignupComponent;
  let fixture: ComponentFixture<SignupComponent>;
  let authService: jasmine.SpyObj<Partial<AuthService>>;
  let dataService: jasmine.SpyObj<Partial<DataService>>;
  let userDetailsSubject: Subject<UserDetails>;
  let router: jasmine.SpyObj<Partial<Router>>;

  beforeEach(async(() => {
    userDetailsSubject = new Subject<UserDetails>();
    authService = {isLoggedIn: jasmine.createSpy().and.returnValue(false)};
    dataService = {
      getUserDetails:
          jasmine.createSpy().and.returnValue(userDetailsSubject.asObservable())
    };
    router = {navigate: jasmine.createSpy()};

    TestBed
        .configureTestingModule({
          declarations: [SignupComponent],
          imports: [
            MatButtonModule,
            ReactiveFormsModule,
          ],
          providers: [
            {provide: AuthService, useValue: authService},
            {provide: DataService, useValue: dataService},
            {provide: Router, useValue: router}
          ]
        })
        .compileComponents();

    fixture = TestBed.createComponent(SignupComponent);
    component = fixture.componentInstance;
  }));

  describe('OnInit', () => {
    it('should route to home page if already logged in', () => {
      authService.isLoggedIn.and.returnValue(true);
      fixture.detectChanges();

      expect(router.navigate).toHaveBeenCalledWith(['/']);
    });

    it('should not route to home page if not logged in', () => {
      authService.isLoggedIn.and.returnValue(false);
      fixture.detectChanges();

      expect(router.navigate).not.toHaveBeenCalledWith(['/']);
    });
  });

  describe('after OnInit', () => {
    beforeEach(() => {
      fixture.detectChanges();
    });

    for (const control_id of FORM_CONTROL_IDS) {
      it(`should have all the ${control_id} control properly attached`, () => {
        expectInputControlToBeAttachedToForm(
            fixture, control_id, component.form);
      });
    }

    it('should get email associated with token', () => {
      component.form.patchValue({'token': 'some-token'});
      expect(dataService.getUserDetails).toHaveBeenCalledWith('some-token');

      userDetailsSubject.next({github: {email: 'hans@solo.com'}});
      expect(component.email).toBe('hans@solo.com');
    });

    it('should show error if getting email errors out', () => {
      component.form.patchValue({'token': 'some-token'});
      userDetailsSubject.error({error: {message: 'ya done messed up'}});
      fixture.detectChanges();

      expect(getElementText(fixture.debugElement, '.form-error'))
          .toBe('ya done messed up');
    });
  });
});
