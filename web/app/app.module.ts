import {HttpClientModule} from '@angular/common/http';
import {NgModule} from '@angular/core';
import {MatCardModule} from '@angular/material/card';
import {MatIconModule} from '@angular/material/icon';
import {MatTableModule} from '@angular/material/table';
import {MatToolbarModule} from '@angular/material/toolbar';
import {MatProgressSpinnerModule} from '@angular/material/progress-spinner'
import {BrowserModule} from '@angular/platform-browser';
import {MomentModule} from 'ngx-moment';

import {AppRoutingModule} from './/app-routing.module';
import {AppComponent} from './app.component';
import {DashboardComponent} from './dashboard/dashboard.component';
import {ProjectComponent} from './project/project.component';
import {DataService} from './services/data.service';

@NgModule({
  declarations: [AppComponent, DashboardComponent, ProjectComponent],
  imports: [
    BrowserModule,
    HttpClientModule,
    AppRoutingModule,
    /** Angular Material Imports */
    MatCardModule,
    MatTableModule,
    MatIconModule,
    MatToolbarModule,
    MatProgressSpinnerModule,
    /** Third-Party Module Imports */
    MomentModule,
  ],
  providers: [DataService],
  bootstrap: [AppComponent]
})
export class AppModule {
}
