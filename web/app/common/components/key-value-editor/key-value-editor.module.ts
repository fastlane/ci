import {CommonModule} from '@angular/common';
import {NgModule} from '@angular/core';
import {ReactiveFormsModule} from '@angular/forms';
import {MatButtonModule, MatIconModule} from '@angular/material';

import {KeyValueEditorComponent} from './key-value-editor.component';

@NgModule({
  declarations: [KeyValueEditorComponent],
  imports: [
    /** Angular Library Imports */
    ReactiveFormsModule, CommonModule,
    /** Internal Imports */
    /** Angular Material Imports */
    MatIconModule, MatButtonModule,
    /** Third-Party Module Imports */
  ],
  exports: [KeyValueEditorComponent]
})
export class KeyValueEditorModule {
}
