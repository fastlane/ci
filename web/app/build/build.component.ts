import {Component, OnInit} from '@angular/core';
import {ActivatedRoute} from '@angular/router';
import {ParamMap} from '@angular/router/src/shared';
import {Subject} from 'rxjs/Subject';

import {BuildLogWebsocketService} from '../services/build-log-websocket.service';

@Component({
  selector: 'fci-build',
  templateUrl: './build.component.html',
  styleUrls: ['./build.component.scss']
})
export class BuildComponent implements OnInit {
  logs = '';

  constructor(
      private readonly buildLogSocketService: BuildLogWebsocketService,
      private readonly route: ActivatedRoute) {}

  ngOnInit() {
    this.route.paramMap
        .switchMap(
            (params: ParamMap) => this.buildLogSocketService.connect(
                params.get('projectId'), params.get('buildId')))
        .subscribe((message) => {
          // TODO: this will be more than a string later on. Let's define a log
          // line model.
          this.logs += message.data;
        });
  }
}
