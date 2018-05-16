import {async, ComponentFixture, TestBed} from '@angular/core/testing';
import {ActivatedRoute, convertToParamMap} from '@angular/router';
import {Observable} from 'rxjs/Observable';
import {Subject} from 'rxjs/Subject';

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
    fixture.detectChanges();
  });

  it('should start socket connection with correct project/build IDs', () => {
    expect(buildLogWebsocketService.connect).toHaveBeenCalledWith('123', '1');
  });

  it('should update logs as they come in', () => {
    expect(component.logs).toBe('');
    socketSubject.next(new MessageEvent('type', {data: 'log1'}));
    expect(component.logs).toBe('log1');
    socketSubject.next(new MessageEvent('type', {data: 'log2'}));
    expect(component.logs).toBe('log1log2');
  });
});
