import {async, ComponentFixture, TestBed} from '@angular/core/testing';
import {ActivatedRoute, convertToParamMap, DefaultUrlSerializer} from '@angular/router';
import {RouterTestingModule} from '@angular/router/testing';
import {Observable} from 'rxjs/Observable';

import {WindowService} from '../services/window.service';

import {AuthComponent} from './auth.component';

describe('AuthComponent', () => {
  let component: AuthComponent;
  let fixture: ComponentFixture<AuthComponent>;

  let window: Partial<Window>;
  let windowOpener: Partial<Window>;
  let location: Partial<Location>;
  let windowService: Partial<WindowService>;

  function setupWindowServiceMocks() {
    location = {origin: 'fake-origin'};
    windowOpener = {postMessage: jasmine.createSpy()};
    window = {
      location: location as Location,
      opener: windowOpener,
    };

    windowService = {
      nativeWindow: window as Window,
    };
  }

  beforeEach(async(() => {
    TestBed
        .configureTestingModule({
          imports: [RouterTestingModule],
          declarations: [AuthComponent],
          providers: [
            {
              provide: ActivatedRoute,
              useValue: {
                url: Observable.of(
                    new DefaultUrlSerializer().parse('auth/github')),
                queryParams: Observable.of(convertToParamMap({code: '123'}))
              }
            },
            {
              provide: WindowService,
              useValue: windowService,
            }
          ]
        })
        .compileComponents();

    fixture = TestBed.createComponent(AuthComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  }));

  it('should create navigate to dashboard if not opened by another window',
     () => {
       expect(component).toBeTruthy();
     });
});
