import {CommonModule} from '@angular/common';
import {NgModule} from '@angular/core';
import {MatCardModule, MatTableModule} from '@angular/material';
import {RouterModule} from '@angular/router';
import {MomentModule} from 'ngx-moment';

import {CommonComponentsModule} from '../common/components/common-components.module';
import {ToolbarModule} from '../common/components/toolbar/toolbar.module';
import {DashboardComponent} from '../dashboard/dashboard.component';
import {ProjectComponent} from '../project/project.component';
import {DataService} from '../services/data.service';

@NgModule({
  declarations: [
    ProjectComponent,
  ],
  entryComponents: [
    ProjectComponent,
  ],
  imports: [
    /** Angular Library Imports */
    CommonModule,
    /** Internal Imports */
    CommonComponentsModule, ToolbarModule,
    /** Angular Material Imports */
    MatCardModule, MatTableModule,
    /** Third-Party Module Imports */
    MomentModule,  // For Date relative time pipes
  ],
  providers: [DataService],
})
export class ProjectModule {
}
