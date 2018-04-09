import {Component, OnInit} from '@angular/core';

import {ProjectSummary} from '../models/project_summary';
import {DataService} from '../services/data.service';

@Component({
  selector: 'app-overview',
  templateUrl: './overview.component.html',
  styleUrls: ['./overview.component.scss']
})
export class OverviewComponent implements OnInit {
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
