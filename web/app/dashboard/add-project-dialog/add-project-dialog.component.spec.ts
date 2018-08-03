import {CommonModule} from '@angular/common';
import {DebugElement} from '@angular/core';
import {async, ComponentFixture, fakeAsync, TestBed} from '@angular/core/testing';
import {FormsModule, ReactiveFormsModule} from '@angular/forms';
import {MatButtonModule, MatDialogModule, MatDialogRef, MatIconModule, MatProgressSpinnerModule, MatSelectModule} from '@angular/material';
import {MAT_DIALOG_DATA} from '@angular/material';
import {By} from '@angular/platform-browser';
import {BrowserAnimationsModule} from '@angular/platform-browser/animations';
import {Subject} from 'rxjs/Subject';

import {FormSpinnerModule} from '../../common/components/form-spinner/form-spinner.module';
// tslint:disable-next-line:max-line-length
import {expectElementNotToExist, expectElementToExist, expectInputControlToBeAttachedToForm, getElement, getElementText} from '../../common/test_helpers/element_helper_functions';
import {mockLanes, mockLanesResponse} from '../../common/test_helpers/mock_lane_data';
import {mockProjectSummary} from '../../common/test_helpers/mock_project_data';
import {mockRepositoryList} from '../../common/test_helpers/mock_repository_data';
import {Lane} from '../../models/lane';
import {ProjectSummary} from '../../models/project_summary';
import {Repository} from '../../models/repository';
import {DataService} from '../../services/data.service';

import {AddProjectDialogComponent} from './add-project-dialog.component';

describe('AddProjectDialogComponent', () => {
  let component: AddProjectDialogComponent;
  let fixture: ComponentFixture<AddProjectDialogComponent>;
  let fixtureEl: DebugElement;
  let reposSubject: Subject<Repository[]>;
  let projectSubject: Subject<ProjectSummary>;
  let lanesSubject: Subject<Lane[]>;
  let dataService: jasmine.SpyObj<Partial<DataService>>;
  let projectNameEl: HTMLInputElement;
  let repoSelectEl: HTMLElement;
  let laneSelectEl: HTMLElement;
  let triggerSelectEl: HTMLElement;
  let dialogRef:
      jasmine.SpyObj<Partial<MatDialogRef<AddProjectDialogComponent>>>;

  beforeEach(async(() => {
    reposSubject = new Subject<Repository[]>();
    projectSubject = new Subject<ProjectSummary>();
    lanesSubject = new Subject<Lane[]>();
    dataService = {
      addProject:
          jasmine.createSpy().and.returnValue(projectSubject.asObservable()),
      getRepoLanes:
          jasmine.createSpy().and.returnValue(lanesSubject.asObservable())
    };
    dialogRef = {close: jasmine.createSpy()};

    TestBed
        .configureTestingModule({
          declarations: [AddProjectDialogComponent],
          providers: [
            {
              provide: MAT_DIALOG_DATA,
              useValue: {repositories: reposSubject.asObservable()}
            },
            {provide: DataService, useValue: dataService},
            {provide: MatDialogRef, useValue: dialogRef}
          ],
          imports: [
            MatDialogModule, MatButtonModule, MatSelectModule, MatIconModule,
            CommonModule, ReactiveFormsModule, FormSpinnerModule,
            MatProgressSpinnerModule, BrowserAnimationsModule
          ]
        })
        .compileComponents();

    fixture = TestBed.createComponent(AddProjectDialogComponent);
    fixtureEl = fixture.debugElement;
    component = fixture.componentInstance;
    fixture.detectChanges();

    projectNameEl = getElement(fixtureEl, 'input[placeholder="Project Name"]')
                        .nativeElement;
    repoSelectEl = getElement(fixtureEl, '.fci-repo-select').nativeElement;
    laneSelectEl = getElement(fixtureEl, '.fci-lane-select').nativeElement;
    triggerSelectEl =
        getElement(fixtureEl, '.fci-trigger-select').nativeElement;
  }));

  it('Should close dialog when close button is clicked', () => {
    getElement(fixtureEl, '.mat-dialog-actions > .mat-button')
        .nativeElement.click();
    expect(dialogRef.close).toHaveBeenCalled();
  });

  it('Should close dialog when X button is clicked', () => {
    getElement(fixtureEl, '.fci-dialog-icon-close-button')
        .nativeElement.click();
    expect(dialogRef.close).toHaveBeenCalled();
  });

  describe('initialization', () => {
    it('should enable controls once repo data is loaded', async(() => {
         expect(component.form.get('repo').enabled).toBe(false);
         expect(component.form.get('name').enabled).toBe(false);
         expect(component.form.get('trigger').enabled).toBe(false);

         // Load Repos
         reposSubject.next(mockRepositoryList);

         expect(component.form.get('repo').enabled).toBe(true);
         expect(component.form.get('name').enabled).toBe(true);
         expect(component.form.get('trigger').enabled).toBe(true);
       }));

    it('should enable lane once lane data is loaded', async(() => {
         expect(component.form.get('lane').enabled).toBe(false);

         // Load Repos and Lanes
         reposSubject.next(mockRepositoryList);
         lanesSubject.next(mockLanes);

         expect(component.form.get('repo').enabled).toBe(true);
         expect(component.form.get('name').enabled).toBe(true);
         expect(component.form.get('trigger').enabled).toBe(true);
       }));
  });

  describe('repo, lane, project name form controls', () => {
    beforeEach(() => {
      // Load Repos
      reposSubject.next(mockRepositoryList);
      fixture.detectChanges();
    });

    it('should bind the project name input', async(() => {
         component.form.patchValue({'name': 'ProjectX'});
         fixture.detectChanges();

         fixture.whenStable().then(() => {
           expectInputControlToBeAttachedToForm(
               fixture, 'name', component.form);
         });
       }));

    it('should set repo option', () => {
      component.form.patchValue({'repo': 'fastlane/fastlane'});
      fixture.detectChanges();

      expect(repoSelectEl.textContent).toBe('fastlane/fastlane');

      component.form.patchValue({'repo': 'fastlane/ci'});
      fixture.detectChanges();

      expect(repoSelectEl.textContent).toBe('fastlane/ci');
    });

    it('should set lane option', async(() => {
         // Load Lanes
         lanesSubject.next(mockLanes);
         fixture.detectChanges();

         fixture.whenStable().then(() => {
           component.form.patchValue({'lane': 'ios test'});
           fixture.detectChanges();

           expect(laneSelectEl.textContent).toBe('ios test');

           component.form.patchValue({'lane': 'android beta'});
           fixture.detectChanges();

           expect(laneSelectEl.textContent).toBe('android beta');
         });
       }));

    it('should reload lanes if repo changes', () => {
      // Load Lanes
      lanesSubject.next(mockLanes);
      expect(component.isLoadingLanes).toBe(false);
      expect(component.lanes.length).toBe(2);

      // Select the third repo
      component.form.patchValue({'repo': component.repositories[2]});

      // Assert that the new lanes are loaded
      expect(component.isLoadingLanes).toBe(true);
      lanesSubject.next([mockLanes[0]]);
      expect(component.isLoadingLanes).toBe(false);
      expect(component.lanes.length).toBe(1);
    });

    it('should show spinner when lanes are loading', () => {
      expect(component.isLoadingLanes).toBe(true);
      expectElementToExist(fixtureEl, '.fci-lane-form .mat-spinner');

      lanesSubject.next(mockLanes);
      fixture.detectChanges();

      expect(component.isLoadingLanes).toBe(false);
      expectElementNotToExist(fixtureEl, '.fci-lane-form .mat-spinner');
    });
  });

  describe('triggers', () => {
    beforeEach(() => {
      // Load Repos
      reposSubject.next(mockRepositoryList);
      fixture.detectChanges();
    });

    it('should show correct nightly trigger option name', () => {
      component.form.patchValue({'trigger': 'nightly'});
      fixture.detectChanges();

      expect(triggerSelectEl.textContent).toBe('nightly');
    });

    it('should show correct commit option name', () => {
      component.form.patchValue({'trigger': 'commit'});
      fixture.detectChanges();

      expect(triggerSelectEl.textContent).toBe('for every commit');
    });

    it('should show correct PR option name', () => {
      component.form.patchValue({'trigger': 'pull_request'});
      fixture.detectChanges();

      expect(triggerSelectEl.textContent).toBe('for every pull request');
    });

    it('should show time selection when trigger is nightly', () => {
      component.form.patchValue({'trigger': 'nightly'});
      fixture.detectChanges();

      expectElementToExist(fixtureEl, '.fci-hour-select');
      expectElementToExist(fixtureEl, '.fci-am-pm-select');
    });

    it('should not show time selection when trigger is not nightly', () => {
      component.form.patchValue({'trigger': 'commit'});
      fixture.detectChanges();

      expectElementNotToExist(fixtureEl, '.fci-hour-select');
      expectElementNotToExist(fixtureEl, '.fci-am-pm-select');
    });

    it('should set nightly time correctly', async(() => {
         component.form.patchValue({'trigger': 'nightly'});
         fixture.detectChanges();

         const hourEl = getElement(fixtureEl, '.fci-hour-select');
         const amPmEl = getElement(fixtureEl, '.fci-am-pm-select');

         // I think this is needed to load the hour/amPm select in ngIf block
         fixture.whenStable().then(() => {
           fixture.detectChanges();
           expect(getElementText(hourEl)).toBe('12');
           expect(getElementText(amPmEl)).toBe('AM');

           component.form.patchValue({'hour': 2, 'amPm': 'PM'});
           fixture.detectChanges();

           expect(getElementText(hourEl)).toBe('2');
           expect(getElementText(amPmEl)).toBe('PM');
         });
       }));
  });

  describe('#addProject', () => {
    beforeEach(() => {
      // Load Repos
      reposSubject.next(mockRepositoryList);

      // Load Lanes
      lanesSubject.next(mockLanes);
      fixture.detectChanges();

      // Set the name control so the form is valid
      component.form.patchValue({'name': 'fake project'});
    });

    it('should not add project if form is invalid', () => {
      // invalidate form
      component.form.patchValue({'name': ''});
      expect(component.form.valid).toBe(false);

      component.addProject();
      expect(dataService.addProject).not.toHaveBeenCalled();
    });

    it('should add project with correct form data', () => {
      component.form.setValue({
        'name': 'fake name',
        'lane': 'fake lane',
        'repo': 'fake repo',
        'trigger': 'nightly',
        'hour': 2,
        'amPm': 'PM'
      });

      expect(component.form.valid).toBe(true);
      component.addProject();
      expect(dataService.addProject).toHaveBeenCalledWith({
        'project_name': 'fake name',
        'lane': 'fake lane',
        'repo_org': '',
        'repo_name': 'fake repo',
        'trigger_type': 'nightly',
        'branch': 'master',
        'hour': 14,
      });
    });

    it('should emit add project event when project is added', () => {
      let projectSummary: ProjectSummary;
      component.addProject();

      component.projectAdded.subscribe((summary: ProjectSummary) => {
        projectSummary = summary;
      });

      projectSubject.next(mockProjectSummary);
      expect(projectSummary).toBe(mockProjectSummary);
    });

    it('should add the project hour in military time when nightly trigger',
       () => {
         component.form.patchValue({'trigger': 'nightly'});

         // 1PM or 13:00
         component.form.patchValue({'hour': 1, 'amPm': 'PM'});
         component.addProject();

         expect(dataService.addProject.calls.mostRecent().args[0].hour)
             .toBe(13);

         // Midnight or 0:00
         component.form.patchValue({'hour': 12, 'amPm': 'AM'});
         component.addProject();

         expect(dataService.addProject.calls.mostRecent().args[0].hour).toBe(0);
       });

    it('should show spinner while adding project', () => {
      expectElementNotToExist(fixtureEl, '.mat-spinner');

      component.addProject();
      fixture.detectChanges();

      expectElementToExist(fixtureEl, '.mat-spinner');

      projectSubject.next(mockProjectSummary);
      fixture.detectChanges();

      expectElementNotToExist(fixtureEl, '.mat-spinner');
    });

    it('should close dialog on success', async(() => {
         // TODO: figure out how to submit the test from clicking the UI
         // button
         component.addProject();
         projectSubject.next(mockProjectSummary);

         expect(dialogRef.close).toHaveBeenCalled();
       }));
  });
});
