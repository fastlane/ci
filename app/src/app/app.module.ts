import {HttpClientModule} from '@angular/common/http';
import {NgModule} from '@angular/core';
import {MatGridListModule} from '@angular/material';
import {BrowserModule} from '@angular/platform-browser';

import {AppRoutingModule} from './/app-routing.module';
import {AppComponent} from './app.component';
import {DashboardComponent} from './dashboard/dashboard.component';
import {OverviewComponent} from './overview/overview.component';
import {DataService} from './services/data.service';

@NgModule({
  declarations: [AppComponent, DashboardComponent, OverviewComponent],
  imports:
      [BrowserModule, HttpClientModule, AppRoutingModule, MatGridListModule],
  providers: [DataService],
  bootstrap: [AppComponent]
})
export class AppModule {
}
