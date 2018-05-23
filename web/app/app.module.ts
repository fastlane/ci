import {HTTP_INTERCEPTORS, HttpClientModule} from '@angular/common/http';
import {NgModule} from '@angular/core';
import {BrowserModule} from '@angular/platform-browser';
import {MomentModule} from 'ngx-moment';

import {AppRoutingModule} from './/app-routing.module';
import {AppComponent} from './app.component';
import {CommonComponentsModule} from './common/components/common-components.module';
import {AuthInterceptor} from './services/auth.interceptor';
import {DataService} from './services/data.service';
import {SharedMaterialModule} from './shared_material.module';

@NgModule({
  declarations: [
    AppComponent,
  ],
  imports: [
    BrowserModule,
    HttpClientModule,
    AppRoutingModule,
    CommonComponentsModule,
    /** Angular Material Imports */
    SharedMaterialModule,
    /** Third-Party Module Imports */
    MomentModule,
  ],
  providers: [
    DataService,
    {provide: HTTP_INTERCEPTORS, useClass: AuthInterceptor, multi: true}
  ],
  bootstrap: [AppComponent]
})
export class AppModule {
}
