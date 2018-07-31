import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { LogViewerComponent } from './log-viewer.component';
import { LogLineModule } from './log-line/log-line.module';

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
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
