import {NgModule} from '@angular/core';
import {CommonModule} from '@angular/common';

import {LogViewerComponent} from './log-viewer.component';
import {LogLineModule} from './log-line/log-line.module';

@NgModule({
  declarations: [LogViewerComponent],
  imports: [
    /** Angular Library Imports */
    CommonModule,
    /** Internal Imports */
    LogLineModule,
    /** Angular Material Imports */
    /** Third-Party Module Imports */
  ],
  exports: [LogViewerComponent]
})
export class LogViewerModule {
}
