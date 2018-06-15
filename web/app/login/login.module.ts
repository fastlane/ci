import {CommonModule} from '@angular/common';
import {NgModule} from '@angular/core';
import {FormsModule} from '@angular/forms';
import {MatButtonModule} from '@angular/material';

import {AuthService} from '../services/auth.service';

import {LoginComponent} from './login.component';

@NgModule({
  declarations: [
    LoginComponent,
  ],
  entryComponents: [
    LoginComponent,
  ],
  imports: [
    /** Angular Library Imports */
    CommonModule, FormsModule,
    /** Internal Imports */
    /** Angular Material Imports */
    MatButtonModule,
    /** Third-Party Module Imports */
  ],
  providers: [AuthService],
})
export class LoginModule {
}
