import {Component, DebugElement} from '@angular/core';
import {async, ComponentFixture, TestBed} from '@angular/core/testing';
import {ReactiveFormsModule} from '@angular/forms';
import {FormArray} from '@angular/forms';
import {MatIconModule} from '@angular/material';

import {getElement} from '../../test_helpers/element_helper_functions';

import {KeyValueEditorComponent, KeyValuePair} from './key-value-editor.component';

@Component({
  template: `
    <fci-key-value-editor [formArray]="formArray" [initialPairsData]="initData">
    </fci-key-value-editor>`
})
class TestHostComponent {
  formArray: FormArray;
  initData: KeyValuePair[];
}

describe('KeyValueEditorComponent', () => {
  let hostComponent: TestHostComponent;
  let editorComponent: KeyValueEditorComponent;
  let fixture: ComponentFixture<TestHostComponent>;
  let fixtureEl: DebugElement;

  beforeEach(async(() => {
    TestBed
        .configureTestingModule({
          declarations: [KeyValueEditorComponent, TestHostComponent],
          imports: [ReactiveFormsModule, MatIconModule]
        })
        .compileComponents();

    fixture = TestBed.createComponent(TestHostComponent);
    fixtureEl = fixture.debugElement;
    hostComponent = fixture.componentInstance;

    hostComponent.formArray = new FormArray([]);
    hostComponent.initData =
        [{key: 'key1', value: 'value1'}, {key: 'key2', value: 'value2'}];
    editorComponent =
        getElement(fixtureEl, 'fci-key-value-editor').componentInstance;
    fixture.detectChanges();
  }));

  describe('Unit Tests', () => {
    it('should add a control for each initial pair data', () => {
      expect(editorComponent.formArray.controls.length).toBe(2);
      expect(editorComponent.formArray.controls[0].value.key).toBe('key1');
      expect(editorComponent.formArray.controls[1].value.value).toBe('value2');
    });
    it('should not setup if formArray input is already configured', () => {});
    it('#addNewPairControl should remove pair control', () => {});

    describe('#addNewPairControl', () => {
      it('should push new pair control to stack', () => {});
      it('should clear the new pair control', () => {});
    });
  });

  describe('Shallow Tests', () => {
    it('should have the new pair controls attached to their input Elements',
       () => {});
    it('should have the added pair controls attached to their input Elements',
       () => {});
    it('should disable the add pair button if either field is empty', () => {});
    it('should push new row after clicking the add pair button', () => {});
    it('should delete row after clicking the remove pair button', () => {});
  });
});
