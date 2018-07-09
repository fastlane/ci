import {Component, ElementRef, EventEmitter, Inject, OnInit, ViewChild} from '@angular/core';
import {FormBuilder, FormGroup, Validators} from '@angular/forms';
import {MAT_DIALOG_DATA, MatDialogRef} from '@angular/material';
import * as moment from 'moment';
import {Observable} from 'rxjs/Observable';

import {Lane} from '../../models/lane';
import {ProjectSummary} from '../../models/project_summary';
import {Repository} from '../../models/repository';
import {AddProjectRequest, DataService} from '../../services/data.service';

export interface AddProjectDialogConfig {
  repositories: Observable<Repository[]>;
}

interface TriggerOption {
  viewValue: string;
  value: 'commit' | 'pull_request' | 'nightly';
}

const TRIGGER_OPTIONS: TriggerOption[] = [
  { viewValue: 'for every commit', value: 'commit' },
  { viewValue: 'for every pull request', value: 'pull_request' },
  { viewValue: 'nightly', value: 'nightly' },
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


function buildProjectForm(fb: FormBuilder): FormGroup {
  return fb.group({
    'name': [{value: '', disabled: true}, Validators.required],
    'repo': [{value: '', disabled: true}, Validators.required],
    'lane': [{value: '', disabled: true}, Validators.required],
    'trigger': [{value: 'commit', disabled: true}, Validators.required],
    'hour': [12],
    'amPm': ['AM'],
  });
}

@Component({
  selector: 'fci-add-project-dialog',
  templateUrl: './add-project-dialog.component.html',
  styleUrls: ['./add-project-dialog.component.scss']
})
export class AddProjectDialogComponent {
  @ViewChild('projectNameControl') projectNameControl: ElementRef;
  isLoadingRepositories = true;
  isLoadingLanes = false;
  isAddingProject = false;
  repositories: Repository[];
  lanes: string[] = [];
  readonly form: FormGroup;
  readonly TRIGGER_OPTIONS = TRIGGER_OPTIONS;
  readonly HOURS = HOURS;
  readonly projectAdded = new EventEmitter<ProjectSummary>();
  // TODO: Add control for choosing branch
  private readonly branch = 'master';

  constructor(
      @Inject(MAT_DIALOG_DATA) private readonly data: AddProjectDialogConfig,
      private readonly dataService: DataService,
      private readonly dialogRef: MatDialogRef<AddProjectDialogComponent>,
      fb: FormBuilder,
  ) {
    this.form = buildProjectForm(fb);
    this.form.get('repo').valueChanges.subscribe(
        (repo: string) => this.loadRepoLanes(repo));

    this.data.repositories.subscribe((repositories) => {
      this.repositories = repositories;
      this.form.patchValue({'repo': this.repositories[0].fullName});

      // Enable controls now that the initial data is loaded
      this.form.get('repo').enable();
      this.form.get('name').enable();
      this.form.get('trigger').enable();

      this.projectNameControl.nativeElement.focus();
      this.isLoadingRepositories = false;
    });
  }

  loadRepoLanes(repo: string): void {
    this.isLoadingLanes = true;
    this.dataService.getRepoLanes(repo, this.branch).subscribe((lanes) => {
      this.lanes = lanes.map((lane) => lane.getFullName());
      this.form.patchValue({'lane': this.lanes[0]});
      this.form.get('lane').enable();
      this.isLoadingLanes = false;
    });
  }

  addProject(): void {
    // TODO: figure out why invalid lane does not make the form invalid.
    if (this.form.valid) {
      this.isAddingProject = true;

      const newProjectRequest: AddProjectRequest = {
        lane: this.form.get('lane').value,
        repo_org: '',  // TODO: remove this, no longer needed
        branch: this.branch,
        repo_name: this.form.get('repo').value,
        project_name: this.form.get('name').value,
        trigger_type: this.form.get('trigger').value,
      };

      if (newProjectRequest.trigger_type === 'nightly') {
        newProjectRequest.hour = this.getTriggerHours();
      }

      this.dataService.addProject(newProjectRequest)
          .subscribe((newProjectSummary) => {
            // TODO: Show toast that the project was created
            this.isAddingProject = false;
            this.projectAdded.emit(newProjectSummary);
            this.closeDialog();
          });
    }
  }

  closeDialog(): void {
    this.dialogRef.close();
  }

  private getTriggerHours(): number {
    return moment(
               `${this.form.get('hour').value} ${this.form.get('amPm').value}`,
               'H:A')
        .hour();
  }
}
