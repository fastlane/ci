import {DebugElement, Component} from '@angular/core';
import {Location} from '@angular/common';
import {async, ComponentFixture, TestBed, tick, fakeAsync} from '@angular/core/testing';
import {MatCardModule, MatProgressSpinnerModule} from '@angular/material';
import {By} from '@angular/platform-browser';
import {ActivatedRoute, convertToParamMap} from '@angular/router';
import {RouterTestingModule} from '@angular/router/testing';
import {MomentModule} from 'ngx-moment';
import {Observable} from 'rxjs/Observable';
import {Subject} from 'rxjs/Subject';

import {StatusIconModule} from '../common/components/status-icon/status-icon.module';
import {ToolbarModule} from '../common/components/toolbar/toolbar.module';
import {LogViewerModule} from '../common/components/log-viewer/log-viewer.module';
import {BuildStatus} from '../common/constants';
import {expectElementNotToExist, expectElementToExist, getAllElements, getElement} from '../common/test_helpers/element_helper_functions';
import {mockBuild, mockBuildResponse} from '../common/test_helpers/mock_build_data';
import {Build, BuildLogLine} from '../models/build';
import {BuildLogMessageEvent, BuildLogWebsocketService} from '../services/build-log-websocket.service';
import {DataService} from '../services/data.service';

import {BuildComponent} from './build.component';
import {DummyComponent} from '../common/test_helpers/dummy.component';

describe('BuildComponent', () => {
  let location: Location;
  let component: BuildComponent;
  let fixture: ComponentFixture<BuildComponent>;
  let fixtureEl: DebugElement;
  let buildLogWebsocketService:
      jasmine.SpyObj<Partial<BuildLogWebsocketService>>;
  let dataService: jasmine.SpyObj<Partial<DataService>>;
  let socketSubject: Subject<BuildLogMessageEvent>;
  let buildSubject: Subject<Build>;
  let buildLogsSubject: Subject<BuildLogLine[]>;

  beforeEach(() => {
    socketSubject = new Subject<BuildLogMessageEvent>();
    buildSubject = new Subject<Build>();
    buildLogsSubject = new Subject<BuildLogLine[]>();

    buildLogWebsocketService = {
      connect: jasmine.createSpy().and.returnValue(socketSubject.asObservable())
    };
    dataService = {
      getBuild:
          jasmine.createSpy().and.returnValue(buildSubject.asObservable()),
      getBuildLogs:
          jasmine.createSpy().and.returnValue(buildLogsSubject.asObservable())
    };

    TestBed
        .configureTestingModule({

          declarations: [BuildComponent, DummyComponent],
          imports: [
            ToolbarModule, StatusIconModule, RouterTestingModule.withRoutes(
              [{path: '404', component: DummyComponent} ]
            ),
            MatCardModule, MatProgressSpinnerModule, MomentModule, LogViewerModule
          ],
          providers: [
            {
              provide: BuildLogWebsocketService,
              useValue: buildLogWebsocketService
            },
            {provide: DataService, useValue: dataService}, {
              provide: ActivatedRoute,
              useValue: {
                paramMap: Observable.of(
                    convertToParamMap({projectId: '123', buildId: '3'}))
              }
            }
          ]
        })
        .compileComponents();

    fixture = TestBed.createComponent(BuildComponent);
    fixtureEl = fixture.debugElement;
    component = fixture.componentInstance;

    location = TestBed.get(Location);
  });

  describe('Unit tests', () => {
    it('should start socket connection with correct project/build IDs', () => {
      fixture.detectChanges();
      expect(buildLogWebsocketService.connect).toHaveBeenCalledWith('123', 3);
    });

    it('should get and set Build on init', () => {
      fixture.detectChanges();
      expect(dataService.getBuild).toHaveBeenCalledWith('123', 3);

      buildSubject.next(mockBuild);

      expect(component.build).toBe(mockBuild);
    });

    it('should redirect if API returns an error', fakeAsync(() => {
      fixture.detectChanges();
      expect(dataService.getBuild).toHaveBeenCalledWith('123', 3);

      buildSubject.error({});
      tick();

      expect(location.path()).toBe('/404');
    }));

    it('should update logs as they come in', () => {
      fixture.detectChanges();
      expect(component.logs).toEqual([]);
      socketSubject.next(
          new MessageEvent('type', {data: '{"log":{"message": "log1"}}'}));
      expect(component.logs).toEqual([{message: 'log1'}]);
      socketSubject.next(
          new MessageEvent('type', {data: '{"log":{"message": "log2"}}'}));
      expect(component.logs).toEqual([{message: 'log1'}, {message: 'log2'}]);
    });

    it('should update breadcrumb urls after loading params', () => {
      expect(component.breadcrumbs[1].url).toBeUndefined();
      fixture.detectChanges();  // onInit()

      expect(component.breadcrumbs[1].url).toBe('/project/123');
    });

    it('should update breadcrumb labels after loading build', () => {
      expect(component.breadcrumbs[1].label).toBeUndefined();
      expect(component.breadcrumbs[2].label).toBeUndefined();

      fixture.detectChanges();  // onInit()
      buildSubject.next(mockBuild);

      expect(component.breadcrumbs[1].label).toBe('Project');
      expect(component.breadcrumbs[2].label).toBe('Build 3');
    });

    it('should have toolbar with breadcrumbs', () => {
      fixture.detectChanges();  // onInit()

      // toolbar exists
      expect(getAllElements(fixtureEl, '.fci-crumb').length).toBe(3);

      expect(component.breadcrumbs[0].label).toBe('Dashboard');
      expect(component.breadcrumbs[0].url).toBe('/');
      expect(component.breadcrumbs[1].hint).toBe('Project');
      expect(component.breadcrumbs[2].hint).toBe('Build');
    });

    it('should unsubscribe websocket on destroy', () => {
      fixture.detectChanges();  // onInit()
      expect(component.websocketSubscription.closed).toBe(false);
      fixture.destroy();

      expect(component.websocketSubscription.closed).toBe(true);
    });

    it('should not get build logs if build is incomplete ', () => {
      fixture.detectChanges();  // onInit()
      spyOn(mockBuild, 'isComplete').and.returnValue(false);
      expect(component.websocketSubscription.closed).toBe(false);
      buildSubject.next(mockBuild);
      buildLogsSubject.next([{message: 'some logs'}]);

      expect(component.logs.length).toBe(0);
    });
  });

  describe('shallow tests', () => {
    beforeEach(async(() => {
      fixture.detectChanges();  // onInit()
      fixture.whenStable();
    }));

    it('should show connecting while no logs is connecting', () => {
      const logsEl = getElement(fixtureEl, '.fci-build-logs').nativeElement;
      expect(component.logs.length).toBe(0);
      expect(logsEl.innerText).toBe('Connecting...');

      socketSubject.next(
          new MessageEvent('type', {data: '{"log":{"message": "this is a log"}}'}));
      fixture.detectChanges();

      expect(logsEl.innerText.trim()).toBe('this is a log');
    });

    describe('header', () => {
      let headerEl: DebugElement;

      beforeEach(() => {
        headerEl = getElement(fixtureEl, '.fci-build-header');
      });

      it('should show status icon after loading', () => {
        expectElementNotToExist(headerEl, 'fci-status-icon');

        buildSubject.next(mockBuild);
        fixture.detectChanges();

        const iconsEl = getAllElements(headerEl, 'fci-status-icon');
        expect(iconsEl.length).toBe(1);
        expect(iconsEl[0].nativeElement.innerText).toBe('warning');
      });

      it('should show build number in title after loading', () => {
        const titleEl = getElement(headerEl, '.fci-build-title').nativeElement;
        expect(titleEl.innerText).toBe('Build');

        buildSubject.next(mockBuild);
        fixture.detectChanges();

        expect(titleEl.innerText).toBe('Build 3');
      });

      it('should show build description after loading', () => {
        expectElementNotToExist(headerEl, '.fci-build-description');

        buildSubject.next(mockBuild);
        fixture.detectChanges();

        const descriptionsEl =
            getAllElements(headerEl, '.fci-build-description');
        expect(descriptionsEl.length).toBe(1);
        expect(descriptionsEl[0].nativeElement.innerText)
            .toBe(
                'fastlane.ci encountered an error, check fastlane.ci logs for more information');
      });
    });

    describe('build details card', () => {
      let detailsEl: DebugElement;

      beforeEach(() => {
        detailsEl = getElement(fixtureEl, '.fci-build-details');
      });

      it('should show spinner while loading', () => {
        expectElementToExist(detailsEl, '.fci-loading-spinner');

        buildSubject.next(mockBuild);
        fixture.detectChanges();

        expectElementNotToExist(detailsEl, '.fci-loading-spinner');
      });

      describe('after build loaded', () => {
        beforeEach(() => {
          buildSubject.next(mockBuild);
          fixture.detectChanges();
        });

        it('should show build trigger', () => {
          expect(detailsEl.nativeElement.innerText).toContain('TRIGGER');
          expect(detailsEl.nativeElement.innerText).toContain('commit');
        });

        it('should show build branch', () => {
          expect(detailsEl.nativeElement.innerText).toContain('BRANCH');
          expect(detailsEl.nativeElement.innerText).toContain('test-branch');
        });

        it('should show shortened SHA', () => {
          expect(detailsEl.nativeElement.innerText).toContain('SHA');
          expect(detailsEl.nativeElement.innerText).toContain('5903a0');
        });

        it('should show start time', () => {
          expect(detailsEl.nativeElement.innerText).toContain('STARTED');
          // No good time to test the time since it's relative, and always
          // changing
        });

        it('should show duration if build is not pending', () => {
          expect(component.build.status).not.toBe(BuildStatus.PENDING);
          expect(detailsEl.nativeElement.innerText).toContain('DURATION');
          expect(detailsEl.nativeElement.innerText).toContain('2 minutes');
        });

        it('should not show duration if build is pending', () => {
          component.build =
              new Build({...mockBuildResponse, status: 'pending'});
          expect(component.build.status).toBe(BuildStatus.PENDING);
          fixture.detectChanges();

          expect(detailsEl.nativeElement.innerText).not.toContain('DURATION');
          expect(detailsEl.nativeElement.innerText).not.toContain('2 minutes');
        });
      });
    });

    describe('artifacts card', () => {
      let cardEl: DebugElement;

      beforeEach(() => {
        cardEl = getElement(fixtureEl, '.fci-artifacts');
      });

      it('should show spinner while loading', () => {
        expectElementToExist(cardEl, '.fci-loading-spinner');

        buildSubject.next(mockBuild);
        fixture.detectChanges();

        expectElementNotToExist(cardEl, '.fci-loading-spinner');
      });

      describe('after build loaded', () => {
        beforeEach(() => {
          buildSubject.next(mockBuild);
          fixture.detectChanges();
        });

        it('should show artifacts', () => {
          const artifactEls = getAllElements(cardEl, 'div.fci-artifact');

          expect(artifactEls.length).toBe(2);
          expect(artifactEls[0].nativeElement.innerText).toBe('fastlane.log');
          expect(artifactEls[1].nativeElement.innerText).toBe('hack.exe');
        });
      });
    });
  });
});
