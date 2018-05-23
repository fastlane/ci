import {NgModule} from '@angular/core';

import {ToolbarModule} from '../common/components/toolbar/toolbar.module';
import {BuildLogWebsocketService} from '../services/build-log-websocket.service';

import {BuildComponent} from './build.component';

@NgModule({
  declarations: [BuildComponent],
  entryComponents: [BuildComponent],
  imports: [
    /** Angular Library Imports */
    /** Internal Imports */
    ToolbarModule
    /** Angular Material Imports */
    /** Third-Party Module Imports */
  ],
  providers: [BuildLogWebsocketService],
})
export class BuildModule {
}
