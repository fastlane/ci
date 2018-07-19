import {TestBed} from '@angular/core/testing';
import {Router} from '@angular/router';
import {Subject} from 'rxjs/Subject';

import {ConfiguredSections} from '../models/configured_sections';
import {DataService} from '../services/data.service';

import {InitializationProvider} from './initialization.provider';

describe('InitiliazationProvider', () => {
  let dataService: jasmine.SpyObj<Partial<DataService>>;
  let configuredSections: jasmine.SpyObj<Partial<ConfiguredSections>>;
  let initializationProvider: InitializationProvider;
  let router: jasmine.SpyObj<Partial<Router>>;
  let configuredSectionsSubject: Subject<Partial<ConfiguredSections>>;

  beforeEach(() => {
    configuredSectionsSubject = new Subject<Partial<ConfiguredSections>>();
    dataService = {
      getServerConfiguredSections: jasmine.createSpy().and.returnValue(
          configuredSectionsSubject.asObservable())
    };
    router = {navigate: jasmine.createSpy()};
    configuredSections = {areAllSectionsConfigured: jasmine.createSpy()};

    TestBed.configureTestingModule({
      imports: [],
      providers: [
        {provide: DataService, useValue: dataService},
        {provide: Router, useValue: router}, InitializationProvider
      ]
    });

    initializationProvider = TestBed.get(InitializationProvider);
  });

  it('should redirect to onboarding page if the server is not configured',
     () => {
       configuredSections.areAllSectionsConfigured.and.returnValue(false);
       initializationProvider.initialize();
       configuredSectionsSubject.next(configuredSections);

       expect(router.navigate).toHaveBeenCalledWith(['onboard']);
     });


  it('should not redirect to onboarding page if the server is configured',
     () => {
       configuredSections.areAllSectionsConfigured.and.returnValue(true);
       initializationProvider.initialize();
       configuredSectionsSubject.next(configuredSections);

       expect(router.navigate).not.toHaveBeenCalledWith(['onboard']);
     });
});
