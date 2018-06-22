import {Component, HostBinding, OnInit} from '@angular/core';
import {ActivatedRoute} from '@angular/router';
import {ParamMap} from '@angular/router/src/shared';
import {Subject} from 'rxjs/Subject';

import {Breadcrumb} from '../common/components/toolbar/toolbar.component';
import {BuildStatus} from '../common/constants';
import {Build} from '../models/build';
import {BuildLogWebsocketService} from '../services/build-log-websocket.service';
import {DataService} from '../services/data.service';

@Component({
  selector: 'fci-build',
  templateUrl: './build.component.html',
  styleUrls: ['./build.component.scss']
})
export class BuildComponent implements OnInit {
  @HostBinding('class') classes = ['fci-full-height-container'];
  build: Build;
  // TODO: define interface for the logs
  logs: string[] = [];
  readonly BuildStatus = BuildStatus;

  readonly breadcrumbs: Breadcrumb[] =
      [{label: 'Dashboard', url: '/'}, {hint: 'Project'}, {hint: 'Build'}];

  constructor(
      private readonly dataService: DataService,
      private readonly buildLogSocketService: BuildLogWebsocketService,
      private readonly route: ActivatedRoute) {}

  ngOnInit() {
    this.route.paramMap
        .switchMap((params: ParamMap) => {
          const projectId = params.get('projectId');
          const buildNumber = +params.get('buildId');
          this.updateBreadcrumbsLink(projectId);
          this.connectLogSocket(projectId, buildNumber);
          return this.dataService.getBuild(projectId, buildNumber);
        })
        .subscribe((build: Build) => {
          this.build = build;
          this.updateBreadcrumbsLabels(build.projectId, build.number);
        });
  }

  private connectLogSocket(projectId: string, buildNumber: number) {
    this.buildLogSocketService.connect(projectId, buildNumber)
        .subscribe((message) => {
          // TODO: define a log line model.
          this.logs.push(JSON.parse(message.data));
        });
  }

  private updateBreadcrumbsLink(projectId: string): void {
    this.breadcrumbs[1].url = `/project/${projectId}`;
  }

  private updateBreadcrumbsLabels(projectName: string, buildNumber: number):
      void {
    // TODO: get project name from backend
    this.breadcrumbs[1].label = 'Project';
    this.breadcrumbs[2].label = `Build ${buildNumber}`;
  }
}
