import {NgModule} from '@angular/core';
import {RouterModule, Routes} from '@angular/router';

import {AuthComponent, authPathMatcher} from '../auth/auth.component';
import {AuthModule} from '../auth/auth.module';
import {BuildComponent} from '../build/build.component';
import {BuildModule} from '../build/build.module';
import {DashboardComponent} from '../dashboard/dashboard.component';
import {DashboardModule} from '../dashboard/dashboard.module';
import {OnboardComponent} from '../onboard/onboard.component';
import {OnboardModule} from '../onboard/onboard.module';
import {ProjectComponent} from '../project/project.component';
import {ProjectModule} from '../project/project.module';

const routes: Routes = [
  {path: '', redirectTo: '/dashboard', pathMatch: 'full'},
  {path: 'dashboard', component: DashboardComponent},
  {path: 'project/:id', component: ProjectComponent},
  {path: 'project/:projectId/build/:buildId', component: BuildComponent},
  {path: 'onboard', component: OnboardComponent},
  {matcher: authPathMatcher, component: AuthComponent},
];

@NgModule({
  imports: [
    DashboardModule, ProjectModule, BuildModule, OnboardModule, AuthModule,
    RouterModule.forRoot(routes)
  ],
  exports: [RouterModule]
})

export class RoutingModule {
}
