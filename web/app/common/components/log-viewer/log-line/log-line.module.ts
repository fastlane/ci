import {NgModule} from '@angular/core';
import {CommonModule} from '@angular/common';

import {LogLineComponent} from './log-line.component';

@NgModule({
  declarations: [LogLineComponent],
  imports: [
    /** Angular Library Imports */
    CommonModule
    /** Internal Imports */
    /** Angular Material Imports */
    /** Third-Party Module Imports */
  ],
  exports: [LogLineComponent]
})

export class LogLineModule {
}
