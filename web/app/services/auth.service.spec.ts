import {HttpClientTestingModule, HttpTestingController} from '@angular/common/http/testing';
import {inject, TestBed} from '@angular/core/testing';

import {mockLoginResponse, mockTokenExpired, mockTokenNotExpired} from '../common/test_helpers/mock_login_data';

import {AuthResponse, AuthService} from './auth.service';
import {WindowService} from './window.service';


describe('AuthService', () => {
  let mockHttp: HttpTestingController;
  let authService: AuthService;
  let window: Partial<Window>;
  let newWindow: Partial<Window>;
  let location: Partial<Location>;
  let windowService: Partial<WindowService>;
  let mockStorage = {};
  let windowMessageCallback: Function;

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

  function setupWindowServiceMocks() {
    location = {origin: 'fake-origin'};
    newWindow = {location: {href: 'fake-href'} as Location};
    window = {
      location: location as Location,
      open: jasmine.createSpy().and.returnValue(newWindow),
      addEventListener: jasmine.createSpy().and.callFake((_, callback) => {
        windowMessageCallback = callback;
      })
    };

    windowService = {
      nativeWindow: window as Window,
      getExternalUrl: jasmine.createSpy().and.returnValue('redirect.url.com')
    };
  }

  beforeEach(() => {
    spyOn(localStorage, 'getItem').and.callFake(mockLocalStorage.getItem);
    spyOn(localStorage, 'setItem').and.callFake(mockLocalStorage.setItem);
    spyOn(localStorage, 'removeItem').and.callFake(mockLocalStorage.removeItem);
    setupWindowServiceMocks();

    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [
        AuthService, {
          provide: WindowService,
          useValue: windowService,
        }
      ]
    });

    mockHttp = TestBed.get(HttpTestingController);
    authService = TestBed.get(AuthService);
  });

  afterEach(() => {
    mockLocalStorage.clear();
  });

  describe('authorize', () => {
    it('should open new window and start oauth flow', () => {
      authService.authorize().subscribe();
      const clientIdRequest = mockHttp.expectOne('/api/auth/client_id');
      clientIdRequest.flush({id: '123'});

      expect(newWindow.location.href)
          .toBe(
              'https://github.com/login/oauth/authorize?' +
              'client_id=123&scope=repo&' +
              'redirect_uri=redirect.url.com');
    });

    it('should open new window for authorization', () => {
      authService.authorize().subscribe();
      expect(window.open).toHaveBeenCalledWith('', '_blank');
    });

    describe('OAuth new window webflow', () => {
      it('should get oauth client ID from backend and store it', () => {
        authService.authorize().subscribe();
        const clientIdRequest = mockHttp.expectOne('/api/auth/client_id');
        clientIdRequest.flush({id: '123'});

        expect(mockLocalStorage.getItem('oauth_client_id')).toBe('123');
      });

      it('should bubble up failure if getting client id fails', () => {
        let error;
        authService.authorize().subscribe({
          error: (err) => {
            error = err;
          }
        });

        const clientIdRequest = mockHttp.expectOne('/api/auth/client_id');
        clientIdRequest.flush({}, {status: 500, statusText: 'bad'});

        expect(error.status).toBe(500);
      });

      it('should use correct redirect url', () => {
        authService.authorize().subscribe();
        const clientIdRequest = mockHttp.expectOne('/api/auth/client_id');
        clientIdRequest.flush({id: '123'});

        expect(windowService.getExternalUrl)
            .toHaveBeenCalledWith('/auth/github');
      });
    });

    describe('Flow completion listener', () => {
      function triggerAuthCompletionMessage(origin: string = 'fake-origin') {
        expect(window.addEventListener)
            .toHaveBeenCalledWith('message', windowMessageCallback);
        windowMessageCallback({origin, data: {code: '123'}});
      }

      it('should notify observer when auth token is received', () => {
        let authenticated = false;
        authService.authorize().subscribe(() => {
          authenticated = true;
        });
        triggerAuthCompletionMessage();

        const authRequest = mockHttp.expectOne('/api/auth/github?code=123');
        authRequest.flush({token: '456'});

        expect(authenticated).toBe(true);
      });

      it('should ignore messages incorrect origin', () => {
        authService.authorize().subscribe();
        triggerAuthCompletionMessage('wrong-origin');

        mockHttp.expectNone('/api/auth/github?code=123');
      });

      it('should get auth token with correct code and store it', () => {
        authService.authorize().subscribe();
        triggerAuthCompletionMessage();

        const authRequest = mockHttp.expectOne('/api/auth/github?code=123');
        authRequest.flush({token: '456'});

        expect(mockLocalStorage.getItem('auth_token')).toBe('456');
      });

      it('should bubble up failure if getting auth token', () => {
        let error;
        authService.authorize().subscribe({
          error: (err) => {
            error = err;
          }
        });

        triggerAuthCompletionMessage();

        const authRequest = mockHttp.expectOne('/api/auth/github?code=123');
        authRequest.flush({}, {status: 500, statusText: 'bad'});

        expect(error.status).toBe(500);
      });
    });
  });

  it('should be logged in if token exists in local storage', () => {
    mockLocalStorage.setItem('auth_token', mockTokenNotExpired);
    expect(authService.isLoggedIn()).toBe(true);
  });

  it('should not be logged in if no stored token', () => {
    mockLocalStorage.removeItem('auth_token');
    expect(authService.isLoggedIn()).toBe(false);
  });

  it('should remove token when logging out', () => {
    mockLocalStorage.setItem('auth_token', mockTokenNotExpired);
    authService.logout();
    expect(mockLocalStorage.getItem('auth_token')).toBe(null);
  });
});
