import {DOCUMENT} from '@angular/common';
import {TestBed} from '@angular/core/testing';
import {Subject} from 'rxjs/Subject';
import {DataService} from '../services/data.service';
import {InitializationProvider} from './initialization.provider';

describe('InitiliazationProvider', () => {
  let dataService: jasmine.SpyObj<Partial<DataService>>;
  let document: jasmine.SpyObj<any>;
  let isConfiguredSubject: Subject<boolean>;
  let initializationProvider: InitializationProvider;
  beforeEach(() => {
    isConfiguredSubject = new Subject<boolean>();
    dataService = {
      isServerConfigured: jasmine.createSpy().and.returnValue(
          isConfiguredSubject.asObservable())
    };

    document = {location: {origin: 'fake-host', href: 'fake-href'}};

    TestBed.configureTestingModule({
      imports: [],
      providers: [
        {provide: DataService, useValue: dataService},
        {provide: DOCUMENT, useValue: document}, InitializationProvider
      ]
    });

    initializationProvider = TestBed.get(InitializationProvider);
    document = TestBed.get(DOCUMENT);
  });

  it('should redirect to onboarding erb page if the server is not configured',
     () => {
       expect(document.location.href).toBe('fake-href');
       initializationProvider.initialize();
       isConfiguredSubject.next(false);

       expect(document.location.href).toBe('fake-host/onboarding_erb');
     });


  it('should not redirect to onboarding erb page if the server is configured',
     () => {
       expect(document.location.href).toBe('fake-href');
       initializationProvider.initialize();
       isConfiguredSubject.next(true);

       expect(document.location.href).toBe('fake-href');
     });
});
