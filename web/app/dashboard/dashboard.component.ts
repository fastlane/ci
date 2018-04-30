import {Component, OnInit} from '@angular/core';
import {MAT_DIALOG_DATA, MatDialog, MatDialogRef} from '@angular/material';
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

export class DashboardComponent implements OnInit {
  readonly DISPLAYED_COLUMNS: string[] =
      ['name', 'latestBuild', 'repo', 'lane'];
  isLoading = true;
  projects: ProjectSummary[];
  repositories: Observable<Repository[]>;

  constructor(
      private readonly dataService: DataService,
      private readonly dialog: MatDialog) {}

  ngOnInit() {
    this.dataService.getProjects().subscribe((projects) => {
      this.projects = projects;
      this.isLoading = false;
    });

    // Load repositories for adding a project ahead of time
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

    dialogRef.afterClosed().subscribe(result => {
      console.log('The dialog was closed');
    });
  }
}
