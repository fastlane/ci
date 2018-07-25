import {HttpClientTestingModule, HttpTestingController} from '@angular/common/http/testing';
import {inject, TestBed} from '@angular/core/testing';
import {mockLoginResponse, mockTokenExpired, mockTokenNotExpired} from '../common/test_helpers/mock_login_data';
import {AuthService, LoginResponse} from './auth.service';


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

  it('should go to github oauth UI webflow on login', () => {});

  it('should should request access token from backend using code', () => {
    let loginResponse: LoginResponse;
    authService.login().subscribe((response) => {
      loginResponse = response;
    });

    const loginRequest = mockHttp.expectOne('/api/user/oauth?code=placeholder');
    loginRequest.flush(mockLoginResponse);

    expect(loginResponse.oauth_key).toBe('12345');
  });

  it('should store the token in local storage', () => {
    authService.login().subscribe();

    const loginRequest = mockHttp.expectOne('/api/user/oauth?code=placeholder');
    loginRequest.flush(mockLoginResponse);

    expect(mockLocalStorage.getItem('auth_token')).toBe('12345');
  });

  it('should be logged in if token exists in local storage', () => {
    mockLocalStorage.setItem('auth_token', mockTokenNotExpired);
    expect(authService.isLoggedIn()).toBe(true);
  });

  it('should not be logged in if no stored token', () => {
    mockLocalStorage.removeItem('auth_token');
    expect(authService.isLoggedIn()).toBe(false);
  });
});
