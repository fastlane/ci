import {NgModule} from '@angular/core';

import {WindowService} from '../services/window.service';

import {AuthComponent} from './auth.component';

@NgModule({
  declarations: [AuthComponent],
  imports: [
    /** Angular Library Imports */
    /** Internal Imports */
    /** Angular Material Imports */
    /** Third-Party Module Imports */
  ],
  exports: [AuthComponent],
  providers: [WindowService]
})
export class AuthModule {
}
