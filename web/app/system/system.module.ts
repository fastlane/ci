import {CommonModule} from '@angular/common';
import {NgModule} from '@angular/core';
import {ReactiveFormsModule} from '@angular/forms';
import {MatButtonModule, MatIconModule, MatCardModule} from '@angular/material';

import {PageNotFoundComponent} from './pagenotfound.component';

@NgModule({
  declarations: [
    PageNotFoundComponent,
  ],
  entryComponents: [
    PageNotFoundComponent,
  ],
  imports: [
    /** Angular Library Imports */
    ReactiveFormsModule, CommonModule,
    /** Internal Imports */
    /** Angular Material Imports */
    MatButtonModule, MatCardModule, MatIconModule
    /** Third-Party Module Imports */
  ],
  providers: [],
})
export class SystemModule {
}
