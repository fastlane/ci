import {async, ComponentFixture, TestBed} from '@angular/core/testing';
import {By} from '@angular/platform-browser';
import {ActivatedRoute, convertToParamMap} from '@angular/router';
import {RouterTestingModule} from '@angular/router/testing';
import {Observable} from 'rxjs/Observable';
import {Subject} from 'rxjs/Subject';

import {ToolbarModule} from '../common/components/toolbar/toolbar.module';
import {BuildLogMessageEvent, BuildLogWebsocketService} from '../services/build-log-websocket.service';

import {BuildComponent} from './build.component';

describe('BuildComponent', () => {
  let component: BuildComponent;
  let fixture: ComponentFixture<BuildComponent>;
  let buildLogWebsocketService:
      jasmine.SpyObj<Partial<BuildLogWebsocketService>>;
  let socketSubject: Subject<BuildLogMessageEvent>;

  beforeEach(() => {
    socketSubject = new Subject<BuildLogMessageEvent>();
    buildLogWebsocketService = {
      connect: jasmine.createSpy().and.returnValue(socketSubject.asObservable())
    };
    TestBed
        .configureTestingModule({
          declarations: [BuildComponent],
          imports: [ToolbarModule, RouterTestingModule],
          providers: [
            {
              provide: BuildLogWebsocketService,
              useValue: buildLogWebsocketService
            },
            {
              provide: ActivatedRoute,
              useValue: {
                paramMap: Observable.of(
                    convertToParamMap({projectId: '123', buildId: '1'}))
              }
            }
          ]
        })
        .compileComponents();

    fixture = TestBed.createComponent(BuildComponent);
    component = fixture.componentInstance;
  });

  it('should start socket connection with correct project/build IDs', () => {
    fixture.detectChanges();
    expect(buildLogWebsocketService.connect).toHaveBeenCalledWith('123', '1');
  });

  it('should update logs as they come in', () => {
    fixture.detectChanges();
    expect(component.logs).toBe('');
    socketSubject.next(new MessageEvent('type', {data: 'log1'}));
    expect(component.logs).toBe('log1');
    socketSubject.next(new MessageEvent('type', {data: 'log2'}));
    expect(component.logs).toBe('log1log2');
  });


  it('should update breadcrumbs after loading params', () => {
    expect(component.breadcrumbs[1].url).toBeUndefined();
    fixture.detectChanges();  // onInit()

    expect(component.breadcrumbs[1].url).toBe('/project/123');
  });

  it('should have toolbar with breadcrumbs', () => {
    fixture.detectChanges();  // onInit()

    console.log(fixture.debugElement.query(By.css('.fci-crumb')));
    // toolbar exists
    expect(fixture.debugElement.queryAll(By.css('.fci-crumb')).length).toBe(3);

    expect(component.breadcrumbs[0].label).toBe('Dashboard');
    expect(component.breadcrumbs[0].url).toBe('/');
    expect(component.breadcrumbs[1].hint).toBe('Project');
    expect(component.breadcrumbs[2].hint).toBe('Build');
  });
});
