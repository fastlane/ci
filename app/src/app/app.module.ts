import {HttpClientModule} from '@angular/common/http';
import {NgModule} from '@angular/core';
import {BrowserModule} from '@angular/platform-browser';

import {AppRoutingModule} from './/app-routing.module';
import {AppComponent} from './app.component';
import {DashboardComponent} from './pages/dashboard/dashboard.component';


@NgModule({
  declarations: [AppComponent, DashboardComponent],
  imports: [BrowserModule, HttpClientModule, AppRoutingModule],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule {
}
