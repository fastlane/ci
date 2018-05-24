import {Component, OnInit, ViewChild} from '@angular/core';
import {MAT_DIALOG_DATA, MatDialog, MatDialogRef, MatTable} from '@angular/material';
import {Observable} from 'rxjs/Observable';

import {ProjectSummary, ProjectSummaryResponse} from '../models/project_summary';
import {Repository} from '../models/repository';
import {DataService} from '../services/data.service';

import {AddProjectDialogComponent, AddProjectDialogConfig} from './add-project-dialog/add-project-dialog.component';

@Component({
  selector: 'fci-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.scss']
})

export class DashboardComponent {
  @ViewChild('projectsTable') table: MatTable<ProjectSummary>;
  readonly DISPLAYED_COLUMNS: string[] =
      ['name', 'latestBuild', 'repo', 'lane'];
  isLoading = true;
  projects: ProjectSummary[];
  repositories: Observable<Repository[]>;

  constructor(
      private readonly dataService: DataService,
      private readonly dialog: MatDialog) {
    this.dataService.getProjects().subscribe((projects) => {
      this.projects = projects;
      this.isLoading = false;
    });

    // Load repositories for adding a project ahead of time
    // TODO: figure out subscription to start cold observables.
    this.repositories = this.dataService.getRepos();
  }

  openAddProjectDialog() {
    const dialogRef =
        this.dialog.open<AddProjectDialogComponent, AddProjectDialogConfig>(
            AddProjectDialogComponent, {
              panelClass: 'fci-dialog-xs-fullscreen',
              width: '637px',
              data: {repositories: this.repositories}
            });

    dialogRef.componentInstance.projectAdded.subscribe(
        (newProject: ProjectSummary) => {
          this.projects.push(newProject);
          // Need to re-render rows now that new data is added.
          this.table.renderRows();
        });
  }
}
