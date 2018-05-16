import {Component, Inject, OnInit} from '@angular/core';
import {MAT_DIALOG_DATA, MatDialogRef} from '@angular/material';
import * as moment from 'moment';
import {Observable} from 'rxjs/Observable';

import {Lane} from '../../models/lane';
import {Repository} from '../../models/repository';
import {AddProjectRequest, DataService} from '../../services/data.service';

export interface AddProjectDialogConfig {
  repositories: Observable<Repository[]>;
}

interface TriggerOption {
  viewValue: string;
  value: 'commit'|'nightly';
}

interface TimeSelectorData {
  hour: number;
  isAm: boolean;
}

const TRIGGER_OPTIONS: TriggerOption[] = [
  {viewValue: 'for every commit and PR', value: 'commit'},
  {viewValue: 'nightly', value: 'nightly'},
];

const HOURS: number[] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

// TODO: do something to make these properties camelCase
const BASE_PROJECT_REQUEST: AddProjectRequest = {
  lane: '',
  repo_org: '',
  branch: 'master',
  repo_name: '',
  project_name: '',
  trigger_type: 'commit',
};

function timeSelectDataToMilitaryTime(timeData: TimeSelectorData): number {
  return moment(`${timeData.hour} ${timeData.isAm ? 'AM' : 'PM'}`, 'H:A')
      .hour();
}

@Component({
  selector: 'fci-add-project-dialog',
  templateUrl: './add-project-dialog.component.html',
  styleUrls: ['./add-project-dialog.component.scss']
})
export class AddProjectDialogComponent implements OnInit {
  isLoadingRepositories = true;
  isLoadingLanes = false;
  isAddingProject = false;
  repositories: Repository[];
  lanes: string[] = [];
  readonly timeSelectorData: TimeSelectorData = {hour: 12, isAm: true};
  readonly project = BASE_PROJECT_REQUEST;
  readonly TRIGGER_OPTIONS = TRIGGER_OPTIONS;
  readonly HOURS = HOURS;

  constructor(
      @Inject(MAT_DIALOG_DATA) private readonly data: AddProjectDialogConfig,
      private readonly dataService: DataService,
      private readonly dialogRef: MatDialogRef<AddProjectDialogComponent>,
  ) {}

  ngOnInit(): void {
    this.data.repositories.subscribe((repositories) => {
      this.repositories = repositories;
      this.project.repo_name = this.repositories[0].fullName;
      this.loadRepoLanes();
      this.isLoadingRepositories = false;
    });
  }

  loadRepoLanes(): void {
    this.isLoadingLanes = true;
    this.dataService.getRepoLanes(this.project.repo_name, this.project.branch)
        .subscribe((lanes) => {
          this.lanes = lanes.map((lane) => lane.getFullName());
          this.project.lane = this.lanes[0];
          this.isLoadingLanes = false;
        });
  }

  addProject(): void {
    this.isAddingProject = true;

    if (this.project.trigger_type === 'nightly') {
      this.project.hour = timeSelectDataToMilitaryTime(this.timeSelectorData);
    }

    this.dataService.addProject(this.project).subscribe((project) => {
      // TODO: Show toast that the project was created
      this.isAddingProject = false;
      this.closeDialog();
    });
  }

  closeDialog(): void {
    this.dialogRef.close();
  }
}
