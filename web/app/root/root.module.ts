import {HTTP_INTERCEPTORS, HttpClientModule} from '@angular/common/http';
import {NgModule} from '@angular/core';
import {BrowserModule} from '@angular/platform-browser';
import {MomentModule} from 'ngx-moment';

import {CommonComponentsModule} from '../common/components/common-components.module';
import {AuthInterceptor} from '../services/auth.interceptor';
import {DataService} from '../services/data.service';

import {RootComponent} from './root.component';
import {RoutingModule} from './routing.module';
import {SharedMaterialModule} from './shared_material.module';

@NgModule({
  declarations: [
    RootComponent,
  ],
  imports: [
    BrowserModule,
    HttpClientModule,
    RoutingModule,
    CommonComponentsModule,
    /** Angular Material Imports */
    SharedMaterialModule,
    /** Third-Party Module Imports */
    MomentModule,
  ],
  providers: [
    DataService,
  ],
  bootstrap: [RootComponent]
})
export class RootModule {
}
