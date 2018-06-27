import {HTTP_INTERCEPTORS, HttpClientModule} from '@angular/common/http';
import {APP_INITIALIZER, NgModule} from '@angular/core';
import {BrowserModule} from '@angular/platform-browser';
import {MomentModule} from 'ngx-moment';

import {AuthInterceptor} from '../services/auth.interceptor';
import {DataService} from '../services/data.service';

import {InitializationProvider} from './initialization.provider';
import {RootComponent} from './root.component';
import {RoutingModule} from './routing.module';
import {SharedMaterialModule} from './shared_material.module';

export function initializationProviderFactory(
    provider: InitializationProvider) {
  return () => provider.initialize();
}

@NgModule({
  declarations: [
    RootComponent,
  ],
  imports: [
    BrowserModule,
    HttpClientModule,
    RoutingModule,
    /** Angular Material Imports */
    SharedMaterialModule,
    /** Third-Party Module Imports */
    MomentModule,
  ],
  providers: [
    DataService,
    InitializationProvider,
    {provide: HTTP_INTERCEPTORS, useClass: AuthInterceptor, multi: true},
    {
      provide: APP_INITIALIZER,
      useFactory: initializationProviderFactory,
      deps: [InitializationProvider],
      multi: true
    },
  ],
  bootstrap: [RootComponent]
})
export class RootModule {
}
