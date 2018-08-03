import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { LogViewerComponent } from './log-viewer.component';
import { LogLineModule } from './log-line/log-line.module';
import { LogLine } from './log-line/log-line.component';
import { getElement } from '../../test_helpers/element_helper_functions';

describe('LogViewerComponent', () => {
  let component: LogViewerComponent;
  let fixture: ComponentFixture<LogViewerComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ LogViewerComponent ],
      imports: [LogLineModule]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(LogViewerComponent);
    component = fixture.componentInstance;
    component.logLines = [{
      timestamp: 1533326666,
      message: 'this was a message',
      level: 'DEBUG',
      status: 0,
    }];

    fixture.detectChanges();
  });

/*
  it('should create a log viewer component with log lines', () => {
    const element = getElement(fixture.debugElement, '.fci-log-viewer');
    expect(element.nativeElement.innerHTML).toEqual('');
  });
*/
});
