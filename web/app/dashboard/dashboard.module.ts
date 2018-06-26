import {CommonModule} from '@angular/common';
import {NgModule} from '@angular/core';
import {MatDialogModule} from '@angular/material';
import {BrowserAnimationsModule} from '@angular/platform-browser/animations';
import {RouterModule} from '@angular/router';
import {MomentModule} from 'ngx-moment';

import {StatusIconModule} from '../common/components/status-icon/status-icon.module';
import {DashboardComponent} from '../dashboard/dashboard.component';
import {ProjectComponent} from '../project/project.component';
import {SharedMaterialModule} from '../root/shared_material.module';
import {DataService} from '../services/data.service';

import {AddProjectDialogComponent} from './add-project-dialog/add-project-dialog.component';
import {AddProjectDialogModule} from './add-project-dialog/add-project-dialog.modules';

@NgModule({
  declarations: [
    DashboardComponent,
  ],
  entryComponents: [
    DashboardComponent,
  ],
  imports: [
    /** Angular Library Imports */
    RouterModule,  // For routerLink directive
    CommonModule,  // For ngIf and other common directives
    BrowserAnimationsModule,
    /** Internal Imports */
    StatusIconModule, AddProjectDialogModule,
    /** Angular Material Imports */
    SharedMaterialModule, MatDialogModule,
    /** Third-Party Module Imports */
    MomentModule,  // For Date relative time pipes
  ],
  providers: [DataService],
})
export class DashboardModule {
}
