import 'rxjs/add/operator/switchMap';

import {Component, OnInit} from '@angular/core';
import {ActivatedRoute, ParamMap} from '@angular/router';

import {Project} from '../models/project';
import {DataService} from '../services/data.service';

@Component({
  selector: 'fci-project',
  templateUrl: './project.component.html',
  styleUrls: ['./project.component.scss']
})
export class ProjectComponent implements OnInit {
  readonly DISPLAYED_COLUMNS: string[] = ['number', 'date', 'sha'];
  isLoading = true;
  project: Project;
  readonly projectId: string;

  constructor(
      private readonly dataService: DataService,
      private readonly route: ActivatedRoute) {}

  ngOnInit() {
    this.route.paramMap
        .switchMap(
            (params: ParamMap) => this.dataService.getProject(params.get('id')))
        .subscribe((project) => {
          this.project = project;
          this.isLoading = false;
        });
  }
}
