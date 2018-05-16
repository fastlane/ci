import {HttpClientTestingModule, HttpTestingController} from '@angular/common/http/testing';
import {inject, TestBed} from '@angular/core/testing';
import {mockLoginResponse, mockTokenExpired, mockTokenNotExpired} from '../common/test_helpers/mock_login_data';
import {AuthService, LoginRequest, LoginResponse} from './auth.service';

const FAKE_LOGIN_REQUEST: LoginRequest = {
  email: 'tacoRocat@fastlane.com',
  password: 'wholetthedogsout'
};

describe('AuthService', () => {
  let mockHttp: HttpTestingController;
  let authService: AuthService;
  let mockStorage = {};

  // TODO: generalize this as a test helper
  const mockLocalStorage = {
    getItem: (key: string): string => {
      return key in mockStorage ? mockStorage[key] : null;
    },
    setItem: (key: string, value: string) => {
      mockStorage[key] = `${value}`;
    },
    removeItem: (key: string) => {
      delete mockStorage[key];
    },
    clear: () => {
      mockStorage = {};
    }
  };

  beforeEach(() => {
    spyOn(localStorage, 'getItem').and.callFake(mockLocalStorage.getItem);
    spyOn(localStorage, 'setItem').and.callFake(mockLocalStorage.setItem);

    TestBed.configureTestingModule(
        {imports: [HttpClientTestingModule], providers: [AuthService]});

    mockHttp = TestBed.get(HttpTestingController);
    authService = TestBed.get(AuthService);
  });

  afterEach(() => {
    mockLocalStorage.clear();
  });

  it('should should make login request to backend', () => {
    let loginResponse: LoginResponse;
    authService.login(FAKE_LOGIN_REQUEST).subscribe((response) => {
      loginResponse = response;
    });

    const loginRequest = mockHttp.expectOne('/api/login');
    expect(loginRequest.request.body).toBe(FAKE_LOGIN_REQUEST);
    loginRequest.flush(mockLoginResponse);

    expect(loginResponse.token).toBe('12345');
  });

  it('should store the token in local storage', () => {
    authService.login(FAKE_LOGIN_REQUEST).subscribe();

    const loginRequest = mockHttp.expectOne('/api/login');
    loginRequest.flush(mockLoginResponse);

    expect(mockLocalStorage.getItem('auth_token')).toBe('12345');
  });

  it('should be logged in if token exists in local storage and not Expired',
     () => {
       mockLocalStorage.setItem('auth_token', mockTokenNotExpired);
       expect(authService.isLoggedIn()).toBe(true);
     });

  it('should not be logged in if stored token is expired', () => {
    mockLocalStorage.setItem('auth_token', mockTokenExpired);
    expect(authService.isLoggedIn()).toBe(false);
  });

  it('should not be logged in if no stored token', () => {
    mockLocalStorage.removeItem('auth_token');
    expect(authService.isLoggedIn()).toBe(false);
  });
});
