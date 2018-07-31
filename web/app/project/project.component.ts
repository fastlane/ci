import 'rxjs/add/operator/switchMap';

import {Component, OnInit, ViewChild} from '@angular/core';
import {MatDialog, MatDialogConfig, MatTable} from '@angular/material';
import {ActivatedRoute, ParamMap, Router} from '@angular/router';

import {Breadcrumb} from '../common/components/toolbar/toolbar.component';
import {Build} from '../models/build';
import {BuildSummary} from '../models/build_summary';
import {Project} from '../models/project';
import {DataService} from '../services/data.service';

import {SettingsDialogComponent, SettingsDialogData} from './settings-dialog/settings-dialog.component';

@Component({
  selector: 'fci-project',
  templateUrl: './project.component.html',
  styleUrls: ['./project.component.scss']
})
export class ProjectComponent implements OnInit {
  @ViewChild('buildsTable') table: MatTable<BuildSummary>;
  readonly DISPLAYED_COLUMNS: string[] =
      ['number', 'started', 'duration', 'branch', 'sha'];
  isLoading = true;
  project: Project;
  tableDataSource: BuildSummary[];
  readonly projectId: string;
  readonly breadcrumbs: Breadcrumb[] =
      [{label: 'Dashboard', url: '/'}, {hint: 'Project'}];

  constructor(
      private readonly dataService: DataService,
      private readonly router: Router,
      private readonly route: ActivatedRoute,
      private readonly dialog: MatDialog) {}

  ngOnInit() {
    this.route.paramMap
        .switchMap(
            (params: ParamMap) => this.dataService.getProject(params.get('id')))
        .subscribe((project) => {
          this.project = project;
          this.tableDataSource = this.project.builds;
          this.updateBreadcrumbs(this.project.name);
          this.isLoading = false;
        }, (error) => {
          // @TODO check what type of error we get from api and act accordingly
          this.router.navigate(['/404']);
        });
  }

  rebuild(event: Event, build: BuildSummary) {
    // Make sure it doesn't trigger the row being clicked
    event.stopPropagation();

    this.dataService.rebuild(this.project.id, build.number)
        .subscribe((newBuild) => {
          this.project.builds.unshift(newBuild);
          // Need to re-render rows now that new data is added.
          this.table.renderRows();
        });
  }

  openSettingsDialog() {
    const dialogRef =
        this.dialog.open<SettingsDialogComponent, SettingsDialogData>(
            SettingsDialogComponent, {
              panelClass: 'fci-dialog',
              width: '1028px',
              data: {project: this.project},
            });
  }

  private updateBreadcrumbs(projectName: string) {
    this.breadcrumbs[1].label = projectName;
  }
}
