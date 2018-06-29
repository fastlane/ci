import {NgModule} from '@angular/core';
import {RouterModule, Routes} from '@angular/router';

import {BuildComponent} from '../build/build.component';
import {BuildModule} from '../build/build.module';
import {DashboardComponent} from '../dashboard/dashboard.component';
import {DashboardModule} from '../dashboard/dashboard.module';
import {LoginComponent} from '../login/login.component';
import {LoginModule} from '../login/login.module';
import {ProjectComponent} from '../project/project.component';
import {ProjectModule} from '../project/project.module';
import {SignupComponent} from '../signup/signup.component';
import {SignupModule} from '../signup/signup.module';

const routes: Routes = [
  {path: '', redirectTo: '/dashboard', pathMatch: 'full'},
  {path: 'dashboard', component: DashboardComponent},
  {path: 'project/:id', component: ProjectComponent},
  {path: 'project/:projectId/build/:buildId', component: BuildComponent},
  {path: 'login', component: LoginComponent},
  {path: 'signup', component: SignupComponent},
];

@NgModule({
  imports: [
    DashboardModule, ProjectModule, BuildModule, LoginModule, SignupModule,
    RouterModule.forRoot(routes)
  ],
  exports: [RouterModule]
})

export class RoutingModule {
}
