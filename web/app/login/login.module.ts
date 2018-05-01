import {NgModule} from '@angular/core';
import {MatButtonModule} from '@angular/material';
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
    MatButtonModule
    /** Internal Imports */
    /** Angular Material Imports */
    /** Third-Party Module Imports */
  ],
  providers: [],
})
export class LoginModule {
}
