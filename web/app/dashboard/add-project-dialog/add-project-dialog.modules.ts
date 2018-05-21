import {CommonModule} from '@angular/common';
import {NgModule} from '@angular/core';
import {ReactiveFormsModule} from '@angular/forms';
import {MatButtonModule, MatDialogModule, MatIconModule, MatProgressSpinnerModule, MatSelectModule} from '@angular/material';

import {FormSpinnerModule} from '../../common/components/form-spinner/form-spinner.module';
import {DataService} from '../../services/data.service';

import {AddProjectDialogComponent} from './add-project-dialog.component';

@NgModule({
  declarations: [
    AddProjectDialogComponent,
  ],
  entryComponents: [
    AddProjectDialogComponent,
  ],
  imports: [
    /** Angular Library Imports */
    CommonModule, ReactiveFormsModule,
    /** Internal Imports */
    FormSpinnerModule,
    /** Angular Material Imports */
    MatDialogModule, MatButtonModule, MatSelectModule, MatIconModule,
    MatProgressSpinnerModule
    /** Third-Party Module Imports */
  ],
  providers: [DataService],
})
export class AddProjectDialogModule {
}
