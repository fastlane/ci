import {Component, Input, OnInit} from '@angular/core';
import {FormArray, FormControl, FormGroup, Validators} from '@angular/forms';

export interface KeyValuePair {
  key: string;
  value: string;
}

function createPairFormGroup(key?: string, value?: string) {
  return new FormGroup({
    key: new FormControl(key || '', Validators.required),
    value: new FormControl(value || '', Validators.required),
  });
}

@Component({
  selector: 'fci-key-value-editor',
  templateUrl: './key-value-editor.component.html',
  styleUrls: ['./key-value-editor.component.scss']
})
export class KeyValueEditorComponent implements OnInit {
  @Input() formArray: FormArray;
  @Input() initialPairsData: KeyValuePair[];
  readonly newPairForm: FormGroup;

  constructor() {
    this.newPairForm = createPairFormGroup();
  }

  ngOnInit() {
    this.setupForm();
  }

  private setupForm(): void {
    // If the formArray is already configured, no setup needed.
    if (this.formArray.controls.length > 0) {
      return;
    }

    // Add a new pair editing control for each pair
    for (const {key, value} of this.initialPairsData) {
      this.formArray.push(createPairFormGroup(key, value));
    }

    // Now that the formArray is setup, mark it as in a clean state
    this.formArray.markAsPristine();
  }

  addNewPairControl(): void {
    const {key, value} = this.newPairForm.value as KeyValuePair;
    // Insert it at the beginning to follow stack format
    this.formArray.insert(0, createPairFormGroup(key, value));

    // Clean up for a new value
    this.newPairForm.reset();
  }

  removePairControl(index: number): void {
    this.formArray.removeAt(index);
  }
}
