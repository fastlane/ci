import {DebugElement} from '@angular/core';
import {async, ComponentFixture, TestBed} from '@angular/core/testing';
import {FormsModule} from '@angular/forms';
import {MatButtonModule} from '@angular/material';
import {By} from '@angular/platform-browser';
import {Router} from '@angular/router';
import {Subject} from 'rxjs/Subject';

import {mockLoginResponse} from '../common/test_helpers/mock_login_data';
import {AuthService, LoginResponse} from '../services/auth.service';

import {LoginComponent} from './login.component';

describe('LoginComponent', () => {
  let fixture: ComponentFixture<LoginComponent>;
  let authService: jasmine.SpyObj<Partial<AuthService>>;
  let router: jasmine.SpyObj<Partial<Router>>;
  let loginButtonEl: DebugElement;
  let emailEl: DebugElement;
  let passwordEl: DebugElement;
  let errorEl: DebugElement;
  let loginSubject: Subject<LoginResponse>;

  beforeEach(async(() => {
    loginSubject = new Subject<LoginResponse>();
    authService = {
      login: jasmine.createSpy().and.returnValue(loginSubject.asObservable())
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
    fixture.detectChanges();
    loginButtonEl = fixture.debugElement.query(By.css('button'));
    emailEl = fixture.debugElement.query(By.css('input[type=email]'));
    passwordEl = fixture.debugElement.query(By.css('input[type=password]'));
  }));

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
    function getFormErrorEl() {
      return fixture.debugElement.query(By.css('.form-error'));
    }

    expect(getFormErrorEl()).toBeNull();

    loginButtonEl.triggerEventHandler('click', null);
    fixture.detectChanges();

    expect(getFormErrorEl()).toBeNull();

    loginSubject.error(null);
    fixture.detectChanges();

    errorEl = getFormErrorEl();
    expect(errorEl).not.toBeNull();
    expect(errorEl.nativeElement.textContent.trim()).toBe('Could not log you in. Please try again.');
  });
});
