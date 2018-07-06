import {NgModule} from '@angular/core';
import {MatCardModule} from '@angular/material';

import {MasterDetailCardComponent} from './master-detail-card.component';


@NgModule({
  declarations: [MasterDetailCardComponent],
  imports: [
    /** Angular Library Imports */
    /** Internal Imports */
    /** Angular Material Imports */
    MatCardModule
    /** Third-Party Module Imports */
  ],
  exports: [MasterDetailCardComponent]
})

export class MasterDetailCardModule {
}
