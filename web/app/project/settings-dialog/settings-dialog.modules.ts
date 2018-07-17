import {CommonModule} from '@angular/common';
import {NgModule} from '@angular/core';
import {ReactiveFormsModule} from '@angular/forms';
import {MatButtonModule, MatInputModule} from '@angular/material';

import {KeyValueEditorModule} from '../../common/components/key-value-editor/key-value-editor.module';
import {MasterDetailCardModule} from '../../common/components/master-detail-card/master-detail-card.module';

import {SettingsDialogComponent} from './settings-dialog.component';


@NgModule({
  declarations: [
    SettingsDialogComponent,
  ],
  entryComponents: [
    SettingsDialogComponent,
  ],
  imports: [
    /** Angular Library Imports */
    CommonModule, ReactiveFormsModule,
    /** Internal Imports */
    MasterDetailCardModule, KeyValueEditorModule,
    /** Angular Material Imports */
    MatInputModule, MatButtonModule,
    /** Third-Party Module Imports */
  ],
  providers: [],
})
export class SettingsDialogModule {
}
