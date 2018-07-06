import {CommonModule} from '@angular/common';
import {NgModule} from '@angular/core';
import {ReactiveFormsModule} from '@angular/forms';
import {MatButtonModule, MatIconModule, MatProgressSpinnerModule, MatStepperModule} from '@angular/material';

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
    ReactiveFormsModule, CommonModule,
    /** Internal Imports */
    /** Angular Material Imports */
    MatButtonModule, MatStepperModule, MatProgressSpinnerModule, MatIconModule
    /** Third-Party Module Imports */
  ],
  providers: [],
})
export class OnboardModule {
}
