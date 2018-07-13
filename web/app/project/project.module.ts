import {CommonModule} from '@angular/common';
import {NgModule} from '@angular/core';
import {MatButtonModule, MatCardModule, MatIconModule, MatProgressSpinnerModule, MatTableModule} from '@angular/material';
import {RouterModule} from '@angular/router';
import {MomentModule} from 'ngx-moment';

import {StatusIconModule} from '../common/components/status-icon/status-icon.module';
import {ToolbarModule} from '../common/components/toolbar/toolbar.module';
import {DashboardComponent} from '../dashboard/dashboard.component';
import {ProjectComponent} from '../project/project.component';
import {DataService} from '../services/data.service';
import {SettingsDialogModule} from './settings-dialog/settings-dialog.modules';

@NgModule({
  declarations: [
    ProjectComponent,
  ],
  entryComponents: [
    ProjectComponent,
  ],
  imports: [
    /** Angular Library Imports */
    RouterModule,  // For routerLink directive
    CommonModule,
    /** Internal Imports */
    StatusIconModule, ToolbarModule, SettingsDialogModule,
    /** Angular Material Imports */
    MatCardModule, MatProgressSpinnerModule, MatTableModule, MatIconModule,
    MatButtonModule, MatIconModule,
    /** Third-Party Module Imports */
    MomentModule,  // For Date relative time pipes
  ],
  providers: [DataService],
})
export class ProjectModule {
}
