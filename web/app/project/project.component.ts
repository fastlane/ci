import 'rxjs/add/operator/switchMap';

import {Component, OnInit} from '@angular/core';
import {ActivatedRoute, ParamMap} from '@angular/router';

import {Breadcrumb} from '../common/components/toolbar/toolbar.component';
import {Project} from '../models/project';
import {DataService} from '../services/data.service';

@Component({
  selector: 'fci-project',
  templateUrl: './project.component.html',
  styleUrls: ['./project.component.scss']
})
export class ProjectComponent implements OnInit {
  readonly DISPLAYED_COLUMNS: string[] =
      ['number', 'started', 'duration', 'branch', 'sha'];
  isLoading = true;
  project: Project;
  readonly projectId: string;
  readonly breadcrumbs: Breadcrumb[] =
      [{label: 'Dashboard', url: '/'}, {hint: 'Project'}];

  constructor(
      private readonly dataService: DataService,
      private readonly route: ActivatedRoute) {}

  ngOnInit() {
    this.route.paramMap
        .switchMap(
            (params: ParamMap) => this.dataService.getProject(params.get('id')))
        .subscribe((project) => {
          this.project = project;
          this.updateBreadcrumbs(this.project.name);
          this.isLoading = false;
        });
  }

  private updateBreadcrumbs(projectName: string) {
    this.breadcrumbs[1].label = projectName;
  }
}
