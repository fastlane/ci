import {CommonModule} from '@angular/common';
import {NgModule} from '@angular/core';
import {MatProgressSpinnerModule} from '@angular/material';
import {FormSpinnerComponent} from './form-spinner.component';

@NgModule({
  declarations: [FormSpinnerComponent],
  imports: [MatProgressSpinnerModule],
  exports: [FormSpinnerComponent]
})

export class FormSpinnerModule {
}
