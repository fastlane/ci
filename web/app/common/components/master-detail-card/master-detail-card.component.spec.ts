import {Component} from '@angular/core';
import {async, ComponentFixture, TestBed} from '@angular/core/testing';
import {MatCardModule} from '@angular/material';
import {By} from '@angular/platform-browser';

import {MasterDetailCardComponent} from './master-detail-card.component';

@Component({
  template: `
    <fci-master-detail-card>
      <div fci-master>
        <div class="fci-master-section-label">Section 1</div>
      </div>
      <div fci-detail>
        <div class="fci-detail-content"></div>
      </div>
    </fci-master-detail-card>`
})
class TestHostComponent {
}

describe('MasterDetailCardComponent', () => {
  let fixture: ComponentFixture<MasterDetailCardComponent>;

  beforeEach(async(() => {
    TestBed
        .configureTestingModule({
          declarations: [MasterDetailCardComponent, TestHostComponent],
          imports: [MatCardModule]
        })
        .compileComponents();

    fixture = TestBed.createComponent(TestHostComponent);
    fixture.detectChanges();
  }));

  it('should have nested master section label', () => {
    const sectionLabelEls =
        fixture.debugElement.queryAll(By.css('.fci-master-section-label'));
    expect(sectionLabelEls.length).toBe(1);
  });

  it('should have nested details content', () => {
    const sectionLabelEls =
        fixture.debugElement.queryAll(By.css('.fci-detail-content'));
    expect(sectionLabelEls.length).toBe(1);
  });
});
