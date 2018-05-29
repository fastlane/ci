import {CommonModule} from '@angular/common';
import {NgModule} from '@angular/core';
import {MatIconModule} from '@angular/material';
import {RouterModule} from '@angular/router';

import {ToolbarComponent} from './toolbar.component';

@NgModule({
  declarations: [ToolbarComponent],
  imports: [
    /** Angular Library Imports */
    CommonModule, RouterModule,
    /** Internal Imports */
    /** Angular Material Imports */
    MatIconModule
    /** Third-Party Module Imports */
  ],
  exports: [ToolbarComponent]
})
export class ToolbarModule {
}
