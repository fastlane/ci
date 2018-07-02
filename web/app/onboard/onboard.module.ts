import {NgModule} from '@angular/core';
import {MatButtonModule, MatStepperModule} from '@angular/material';

import {OnboardComponent} from './onboard.component';


@NgModule({
  declarations: [
    OnboardComponent,
  ],
  entryComponents: [
    OnboardComponent,
  ],
  imports: [
    /** Angular Library Imports */
    /** Internal Imports */
    /** Angular Material Imports */
    MatButtonModule, MatStepperModule,
    /** Third-Party Module Imports */
  ],
  providers: [],
})
export class OnboardModule {
}
