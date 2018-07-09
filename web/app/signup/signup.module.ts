import {CommonModule} from '@angular/common';
import {NgModule} from '@angular/core';
import {ReactiveFormsModule} from '@angular/forms';
import {MatButtonModule} from '@angular/material';

import {AuthService} from '../services/auth.service';
import {DataService} from '../services/data.service';

import {SignupComponent} from './signup.component';

@NgModule({
  declarations: [
    SignupComponent,
  ],
  entryComponents: [
    SignupComponent,
  ],
  imports: [
    /** Angular Library Imports */
    CommonModule, ReactiveFormsModule,
    /** Internal Imports */
    /** Angular Material Imports */
    MatButtonModule,
    /** Third-Party Module Imports */
  ],
  providers: [AuthService, DataService],
})
export class SignupModule {
}
