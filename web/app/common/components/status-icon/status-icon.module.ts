import {CommonModule} from '@angular/common';
import {NgModule} from '@angular/core';
import {MatIconModule, MatTooltipModule} from '@angular/material';

import {StatusIconComponent} from './status-icon.component';

@NgModule({
  declarations: [StatusIconComponent],
  imports: [
    /** Angular Library Imports */
    CommonModule,
    /** Internal Imports */
    /** Angular Material Imports */
    MatIconModule, MatTooltipModule,
    /** Third-Party Module Imports */
  ],
  exports: [StatusIconComponent]
})

export class StatusIconModule {
}
