import {CommonModule} from '@angular/common';
import {NgModule} from '@angular/core';
import {MatCardModule, MatProgressSpinnerModule} from '@angular/material';
import {MomentModule} from 'ngx-moment';

import {StatusIconModule} from '../common/components/status-icon/status-icon.module';
import {ToolbarModule} from '../common/components/toolbar/toolbar.module';
import {BuildLogWebsocketService} from '../services/build-log-websocket.service';

import {BuildComponent} from './build.component';
import {LogViewerModule} from '../common/components/log-viewer/log-viewer.module';

@NgModule({
  declarations: [BuildComponent],
  entryComponents: [BuildComponent],
  imports: [
    /** Angular Library Imports */
    CommonModule,
    /** Internal Imports */
    ToolbarModule, StatusIconModule, LogViewerModule,
    /** Angular Material Imports */
    MatCardModule, MatProgressSpinnerModule,
    /** Third-Party Module Imports */
    MomentModule
  ],
  providers: [BuildLogWebsocketService],
})
export class BuildModule {
}
