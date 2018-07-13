import {DebugElement} from '@angular/core';
import {async, ComponentFixture, TestBed} from '@angular/core/testing';
import {FormsModule} from '@angular/forms';
import {MatButtonModule} from '@angular/material';
import {By} from '@angular/platform-browser';
import {Router} from '@angular/router';
import {Subject} from 'rxjs/Subject';

import {expectElementNotToExist, expectElementToExist, getElement, getElementText} from '../common/test_helpers/element_helper_functions';
import {mockLoginResponse} from '../common/test_helpers/mock_login_data';
import {AuthService, LoginResponse} from '../services/auth.service';

import {LoginComponent} from './login.component';

describe('LoginComponent', () => {
  let fixture: ComponentFixture<LoginComponent>;
  let fixtureEl: DebugElement;
  let authService: jasmine.SpyObj<Partial<AuthService>>;
  let router: jasmine.SpyObj<Partial<Router>>;
  let loginButtonEl: DebugElement;
  let emailEl: DebugElement;
  let passwordEl: DebugElement;
  let loginSubject: Subject<LoginResponse>;

  beforeEach(async(() => {
    loginSubject = new Subject<LoginResponse>();
    authService = {
      login: jasmine.createSpy().and.returnValue(loginSubject.asObservable()),
      isLoggedIn: jasmine.createSpy().and.returnValue(false)
    };
    router = {navigate: jasmine.createSpy()};

    TestBed
        .configureTestingModule({
          declarations: [LoginComponent],
          imports: [
            MatButtonModule,
            FormsModule,
          ],
          providers: [
            {provide: AuthService, useValue: authService},
            {provide: Router, useValue: router}
          ]
        })
        .compileComponents();

    fixture = TestBed.createComponent(LoginComponent);
    fixtureEl = fixture.debugElement;
    loginButtonEl = getElement(fixtureEl, 'button');
    emailEl = getElement(fixtureEl, 'input[type=email]');
    passwordEl = getElement(fixtureEl, 'input[type=password]');
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

    it('should call authService to login when login is clicked', () => {
      // Set Input values
      emailEl.nativeElement.value = 'tacoRocat@fastlane.com';
      passwordEl.nativeElement.value = 'whermeydogsat';

      // Dispatch events to notify framework of input value changes
      emailEl.nativeElement.dispatchEvent(new Event('input'));
      passwordEl.nativeElement.dispatchEvent(new Event('input'));
      fixture.detectChanges();  // detect these events and update the component

      loginButtonEl.triggerEventHandler('click', null);

      expect(authService.login).toHaveBeenCalledWith({
        email: 'tacoRocat@fastlane.com',
        password: 'whermeydogsat'
      });
    });

    it('should route to home page when login is complete', () => {
      loginButtonEl.triggerEventHandler('click', null);
      loginSubject.next(mockLoginResponse);

      expect(router.navigate).toHaveBeenCalledWith(['/']);
    });

    it('should disable login button while logging in', () => {
      expect(loginButtonEl.nativeElement.disabled).toBe(false);

      loginButtonEl.triggerEventHandler('click', null);
      fixture.detectChanges();

      expect(loginButtonEl.nativeElement.disabled).toBe(true);

      loginSubject.next(mockLoginResponse);
      fixture.detectChanges();

      expect(loginButtonEl.nativeElement.disabled).toBe(false);
    });

    it('should re-enable login button after a failed login', () => {
      expect(loginButtonEl.nativeElement.disabled).toBe(false);

      loginButtonEl.triggerEventHandler('click', null);
      fixture.detectChanges();

      expect(loginButtonEl.nativeElement.disabled).toBe(true);

      loginSubject.error(null);
      fixture.detectChanges();

      expect(loginButtonEl.nativeElement.disabled).toBe(false);
    });

    it('should show an error message after a failed login attempt', () => {
      expectElementNotToExist(fixtureEl, '.form-error');

      loginButtonEl.triggerEventHandler('click', null);
      fixture.detectChanges();

      expectElementNotToExist(fixtureEl, '.form-error');

      loginSubject.error(null);
      fixture.detectChanges();

      expectElementToExist(fixtureEl, '.form-error');
      expect(getElementText(fixtureEl, '.form-error'))
          .toBe('Could not log you in. Please try again.');
    });
  });
});
