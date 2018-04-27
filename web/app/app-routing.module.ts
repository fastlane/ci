import {NgModule} from '@angular/core';
import {RouterModule, Routes} from '@angular/router';

import {DashboardComponent} from './dashboard/dashboard.component';
import {DashboardModule} from './dashboard/dashboard.module';
import {ProjectComponent} from './project/project.component';

const routes: Routes = [
  {path: '', redirectTo: '/dashboard', pathMatch: 'full'},
  {path: 'dashboard', component: DashboardComponent},
  {path: 'project/:id', component: ProjectComponent}
];

@NgModule({
  imports: [DashboardModule, RouterModule.forRoot(routes)],
  exports: [RouterModule]
})

export class AppRoutingModule {
}
