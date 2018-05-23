import {Component, OnInit} from '@angular/core';
import {ActivatedRoute} from '@angular/router';
import {ParamMap} from '@angular/router/src/shared';
import {Subject} from 'rxjs/Subject';

import {Breadcrumb} from '../common/components/toolbar/toolbar.component';
import {BuildLogWebsocketService} from '../services/build-log-websocket.service';

@Component({
  selector: 'fci-build',
  templateUrl: './build.component.html',
  styleUrls: ['./build.component.scss']
})
export class BuildComponent implements OnInit {
  logs = '';
  readonly breadcrumbs: Breadcrumb[] =
      [{label: 'Dashboard', url: '/'}, {hint: 'Project'}, {hint: 'Build'}];

  constructor(
      private readonly buildLogSocketService: BuildLogWebsocketService,
      private readonly route: ActivatedRoute) {}

  ngOnInit() {
    this.route.paramMap
        .switchMap((params: ParamMap) => {
          this.updateBreadcrumbs(params.get('projectId'));
          return this.buildLogSocketService.connect(
              params.get('projectId'), params.get('buildId'));
        })
        .subscribe((message) => {
          // TODO: this will be more than a string later on. Let's define a log
          // line model.
          this.logs += message.data;
        });
  }

  private updateBreadcrumbs(projectId: string): void {
    // TODO: update the breadcrumbs to have Project name and Build number
    this.breadcrumbs[1].url = `/project/${projectId}`;
  }
}
