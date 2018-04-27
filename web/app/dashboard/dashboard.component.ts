import {Component, OnInit} from '@angular/core';
import {MAT_DIALOG_DATA, MatDialog, MatDialogRef} from '@angular/material';

import {ProjectSummary, ProjectSummaryResponse} from '../models/project_summary';
import {DataService} from '../services/data.service';
import {AddProjectDialogComponent} from './add-project-dialog/add-project-dialog.component';

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

  constructor(
      private readonly dataService: DataService,
      private readonly dialog: MatDialog) {}

  ngOnInit() {
    this.dataService.getProjects().subscribe((projects) => {
      this.projects = projects;
      this.isLoading = false;
    });
  }

  openAddProjectDialog() {
    const dialogRef =
        this.dialog.open(AddProjectDialogComponent, {width: '250px', data: {}});

    dialogRef.afterClosed().subscribe(result => {
      console.log('The dialog was closed');
    });
  }
}
