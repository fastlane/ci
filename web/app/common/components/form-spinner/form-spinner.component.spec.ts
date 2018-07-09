import {async, ComponentFixture, TestBed} from '@angular/core/testing';
import {MatProgressSpinnerModule} from '@angular/material';
import {By} from '@angular/platform-browser';

import {expectElementToExist} from '../../test_helpers/element_helper_functions';

import {FormSpinnerComponent} from './form-spinner.component';

describe('FormSpinnerComponent', () => {
  let fixture: ComponentFixture<FormSpinnerComponent>;

  beforeEach(() => {
    TestBed
        .configureTestingModule({
          declarations: [FormSpinnerComponent],
          imports: [MatProgressSpinnerModule],
        })
        .compileComponents();

    fixture = TestBed.createComponent(FormSpinnerComponent);
    fixture.detectChanges();
  });

  it('should show spinner and mask', () => {
    expectElementToExist(fixture.debugElement, '.mat-spinner');
  });
});
