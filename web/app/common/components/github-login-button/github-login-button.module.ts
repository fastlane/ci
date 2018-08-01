import {NgModule} from '@angular/core';
import {MatButtonModule} from '@angular/material';

import {AuthService} from '../../../services/auth.service';

import {GithubLoginButtonComponent} from './github-login-button.component';


@NgModule({
  declarations: [GithubLoginButtonComponent],
  imports: [
    /** Angular Library Imports */
    /** Internal Imports */
    /** Angular Material Imports */
    MatButtonModule
    /** Third-Party Module Imports */
  ],
  exports: [GithubLoginButtonComponent],
  providers: [AuthService]
})

export class GithubLoginButtonModule {
}
