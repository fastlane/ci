import {TestBed} from '@angular/core/testing';
import {Router} from '@angular/router';
import {Subject} from 'rxjs/Subject';

import {DataService} from '../services/data.service';

import {InitializationProvider} from './initialization.provider';

describe('InitiliazationProvider', () => {
  let dataService: jasmine.SpyObj<Partial<DataService>>;
  let isConfiguredSubject: Subject<boolean>;
  let initializationProvider: InitializationProvider;
  let router: jasmine.SpyObj<Partial<Router>>;

  beforeEach(() => {
    isConfiguredSubject = new Subject<boolean>();
    dataService = {
      isServerConfigured: jasmine.createSpy().and.returnValue(
          isConfiguredSubject.asObservable())
    };
    router = {navigate: jasmine.createSpy()};

    TestBed.configureTestingModule({
      imports: [],
      providers: [
        {provide: DataService, useValue: dataService},
        {provide: Router, useValue: router}, InitializationProvider
      ]
    });

    initializationProvider = TestBed.get(InitializationProvider);
  });

  it('should redirect to onboarding erb page if the server is not configured',
     () => {
       initializationProvider.initialize();
       isConfiguredSubject.next(false);

       expect(router.navigate).toHaveBeenCalledWith(['onboard']);
     });


  it('should not redirect to onboarding erb page if the server is configured',
     () => {
       initializationProvider.initialize();
       isConfiguredSubject.next(true);

       expect(router.navigate).not.toHaveBeenCalledWith(['onboard']);
     });
});
