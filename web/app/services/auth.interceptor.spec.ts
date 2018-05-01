import {HTTP_INTERCEPTORS} from '@angular/common/http';
import {HttpClientTestingModule, HttpTestingController} from '@angular/common/http/testing';
import {inject, TestBed} from '@angular/core/testing';
import {mockProjectListResponse} from '../common/test_helpers/mock_project_data';
import {AuthInterceptor} from './auth.interceptor';
import {DataService} from './data.service';

describe('AuthInterceptor', () => {
  let mockHttp: HttpTestingController;
  let dataService: DataService;
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

    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [
        DataService,
        {
          provide: HTTP_INTERCEPTORS,
          useClass: AuthInterceptor,
          multi: true,
        },
      ]
    });

    mockHttp = TestBed.get(HttpTestingController);
    dataService = TestBed.get(DataService);
  });

  afterEach(() => {
    mockLocalStorage.clear();
  });

  it('should add Authorization header if token is stored', () => {
    mockLocalStorage.setItem('auth_token', '12345');

    dataService.getProjects().subscribe();
    const projectsRequest = mockHttp.expectOne('/data/projects');

    const authHeader = projectsRequest.request.headers.get('Authorization');
    expect(authHeader).toBe('Bearer 12345');
  });

  it('should not add Authorization header no token is stored', () => {
    mockLocalStorage.removeItem('auth_token');

    dataService.getProjects().subscribe();
    const projectsRequest = mockHttp.expectOne('/data/projects');

    const authHeader = projectsRequest.request.headers.get('Authorization');
    expect(authHeader).toBe(null);
  });
});
