import {CommonModule} from '@angular/common';
import {NgModule} from '@angular/core';
import {MatButtonModule, MatCardModule, MatIconModule, MatProgressSpinnerModule} from '@angular/material';
import {MomentModule} from 'ngx-moment';

import {CommonComponentsModule} from '../common/components/common-components.module';
import {ToolbarModule} from '../common/components/toolbar/toolbar.module';
import {BuildLogWebsocketService} from '../services/build-log-websocket.service';

import {BuildComponent} from './build.component';

@NgModule({
  declarations: [BuildComponent],
  entryComponents: [BuildComponent],
  imports: [
    /** Angular Library Imports */
    CommonModule,
    /** Internal Imports */
    ToolbarModule, CommonComponentsModule,
    /** Angular Material Imports */
    MatCardModule, MatProgressSpinnerModule, MatButtonModule, MatIconModule,
    /** Third-Party Module Imports */
    MomentModule
  ],
  providers: [BuildLogWebsocketService],
})
export class BuildModule {
}
