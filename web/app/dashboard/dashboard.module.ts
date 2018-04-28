import {CommonModule} from '@angular/common';
import {NgModule} from '@angular/core';
import {MatDialogModule} from '@angular/material';
import {BrowserAnimationsModule} from '@angular/platform-browser/animations';
import {RouterModule} from '@angular/router';
import {MomentModule} from 'ngx-moment';

import {CommonComponentsModule} from '../common/components/common-components.module';
import {DashboardComponent} from '../dashboard/dashboard.component';
import {ProjectComponent} from '../project/project.component';
import {DataService} from '../services/data.service';
import {SharedMaterialModule} from '../shared_material.module';
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
    CommonComponentsModule, AddProjectDialogModule,
    /** Angular Material Imports */
    SharedMaterialModule, MatDialogModule,
    /** Third-Party Module Imports */
    MomentModule,  // For Date relative time pipes
  ],
  providers: [DataService],
})
export class DashboardModule {
}
