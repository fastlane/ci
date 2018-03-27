import {HttpClientModule} from '@angular/common/http';
import {NgModule} from '@angular/core';
import {MatCardModule} from '@angular/material/card';
import {MatIconModule} from '@angular/material/icon';
import {BrowserModule} from '@angular/platform-browser';

import {AppRoutingModule} from './/app-routing.module';
import {AppComponent} from './app.component';
import {DashboardComponent} from './dashboard/dashboard.component';
import {OverviewComponent} from './overview/overview.component';
import {DataService} from './services/data.service';

@NgModule({
  declarations: [AppComponent, DashboardComponent, OverviewComponent],
  imports: [
    BrowserModule,
    HttpClientModule,
    AppRoutingModule,
    /** Angular Material Imports */
    MatCardModule,
    MatIconModule,
  ],
  providers: [DataService],
  bootstrap: [AppComponent]
})
export class AppModule {
}
