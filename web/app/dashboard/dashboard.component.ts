import {Component, OnInit} from '@angular/core';

import {ProjectSummary, ProjectSummaryResponse} from '../models/project_summary';
import {DataService} from '../services/data.service';

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.scss']
})

export class DashboardComponent implements OnInit {
  readonly DISPLAYED_COLUMNS: string[] =
      ['name', 'latestBuild', 'repo', 'lane'];
  isLoading = true;
  projects: ProjectSummary[];
  constructor(private readonly dataService: DataService) {}

  ngOnInit() {
    this.dataService.getProjects().subscribe((projects) => {
      this.projects = projects;
      this.isLoading = false;
    });
  }
}
