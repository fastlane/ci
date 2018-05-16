import {CommonModule} from '@angular/common';
import {async, ComponentFixture, fakeAsync, TestBed} from '@angular/core/testing';
import {FormsModule} from '@angular/forms';
import {MatButtonModule, MatDialogModule, MatIconModule, MatProgressSpinnerModule, MatSelectModule} from '@angular/material';
import {MAT_DIALOG_DATA} from '@angular/material';
import {By} from '@angular/platform-browser';
import {BrowserAnimationsModule} from '@angular/platform-browser/animations';
import {Subject} from 'rxjs/Subject';

import {FormSpinnerModule} from '../../common/components/form-spinner/form-spinner.module';
import {mockLanes, mockLanesResponse} from '../../common/test_helpers/mock_lane_data';
import {mockProject} from '../../common/test_helpers/mock_project_data';
import {mockRepositoryList} from '../../common/test_helpers/mock_repository_data';
import {Lane} from '../../models/lane';
import {Project} from '../../models/project';
import {Repository} from '../../models/repository';
import {DataService} from '../../services/data.service';

import {AddProjectDialogComponent} from './add-project-dialog.component';

describe('AddProjectDialogComponent', () => {
  let component: AddProjectDialogComponent;
  let fixture: ComponentFixture<AddProjectDialogComponent>;
  let reposSubject: Subject<Repository[]>;
  let projectSubject: Subject<Project>;
  let lanesSubject: Subject<Lane[]>;
  let dataService: jasmine.SpyObj<Partial<DataService>>;
  let projectNameEl: HTMLInputElement;
  let repoSelectEl: HTMLElement;
  let laneSelectEl: HTMLElement;
  let triggerSelectEl: HTMLElement;
  let addProjectButtonEl: HTMLButtonElement;

  beforeEach(async(() => {
    reposSubject = new Subject<Repository[]>();
    projectSubject = new Subject<Project>();
    lanesSubject = new Subject<Lane[]>();
    dataService = {
      addProject:
          jasmine.createSpy().and.returnValue(projectSubject.asObservable()),
      getRepoLanes:
          jasmine.createSpy().and.returnValue(lanesSubject.asObservable())
    };

    TestBed
        .configureTestingModule({
          declarations: [AddProjectDialogComponent],
          providers: [
            {
              provide: MAT_DIALOG_DATA,
              useValue: {repositories: reposSubject.asObservable()}
            },
            {provide: DataService, useValue: dataService}
          ],
          imports: [
            MatDialogModule, MatButtonModule, MatSelectModule, MatIconModule,
            CommonModule, FormsModule, FormSpinnerModule,
            MatProgressSpinnerModule, BrowserAnimationsModule
          ]
        })
        .compileComponents();

    fixture = TestBed.createComponent(AddProjectDialogComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();

    projectNameEl =
        fixture.debugElement.query(By.css('input[placeholder="Project Name"]'))
            .nativeElement;
    repoSelectEl =
        fixture.debugElement.query(By.css('.fci-repo-select')).nativeElement;
    laneSelectEl =
        fixture.debugElement.query(By.css('.fci-lane-select')).nativeElement;
    triggerSelectEl =
        fixture.debugElement.query(By.css('.fci-trigger-select')).nativeElement;
    addProjectButtonEl =
        fixture.debugElement.query(By.css('button.mat-primary')).nativeElement;
  }));

  describe('repo, lane, project name form controls', () => {
    beforeEach(() => {
      // Load Repos
      reposSubject.next(mockRepositoryList);
      fixture.detectChanges();
    });

    it('should two way bind the project name input', async(() => {
         const projectInput = fixture.debugElement.query(
             By.css('input[placeholder="Project Name"]'));
         component.project.project_name = 'ProjectX';
         fixture.detectChanges();

         // ngModel is async, need to wait for it to stabilize
         fixture.whenStable().then(() => {
           expect(projectNameEl.value).toBe('ProjectX');

           projectNameEl.value = 'ProjectY';
           projectNameEl.dispatchEvent(new Event('input'));
           fixture.detectChanges();

           expect(component.project.project_name).toBe('ProjectY');
         });
       }));

    it('should set repo option', () => {
      component.project.repo_name = 'fastlane/fastlane';
      fixture.detectChanges();

      expect(repoSelectEl.textContent).toBe('fastlane/fastlane');

      component.project.repo_name = 'fastlane/ci';
      fixture.detectChanges();

      expect(repoSelectEl.textContent).toBe('fastlane/ci');
    });

    it('should set lane option', async(() => {
         // Load Lanes
         lanesSubject.next(mockLanes);
         fixture.detectChanges();

         fixture.whenStable().then(() => {
           component.project.lane = 'ios test';
           fixture.detectChanges();

           expect(laneSelectEl.textContent).toBe('ios test');

           component.project.lane = 'android beta';
           fixture.detectChanges();

           expect(laneSelectEl.textContent).toBe('android beta');
         });
       }));

    it('should reload lanes if repo changes', async(() => {
         // Load Lanes
         lanesSubject.next(mockLanes);
         expect(component.isLoadingLanes).toBe(false);
         expect(component.lanes.length).toBe(2);

         fixture.whenStable().then(() => {
           fixture.detectChanges();
           // Open select options
           const repoSelectTriggerEl =
               fixture.debugElement
                   .query(By.css('.fci-repo-select .mat-select-trigger'))
                   .nativeElement;
           repoSelectTriggerEl.click();
           fixture.detectChanges();

           // Select the third option
           const repoSelectOptionsEl =
               fixture.debugElement.queryAll(By.css('.mat-option'));
           expect(repoSelectOptionsEl.length).toBe(3);
           repoSelectOptionsEl[2].nativeElement.click();
           fixture.detectChanges();

           expect(repoSelectEl.textContent).toBe('fastlane/onboarding');

           // Assert that the new lanes are loaded
           expect(component.isLoadingLanes).toBe(true);
           lanesSubject.next([mockLanes[0]]);
           expect(component.isLoadingLanes).toBe(false);
           expect(component.lanes.length).toBe(1);
         });
       }));

    it('should show spinner when lanes are loading', () => {
      expect(component.isLoadingLanes).toBe(true);
      let laneSpinnerEl =
          fixture.debugElement.queryAll(By.css('.fci-lane-form .mat-spinner'));

      expect(laneSpinnerEl.length).toBe(1);

      lanesSubject.next(mockLanes);
      fixture.detectChanges();

      laneSpinnerEl =
          fixture.debugElement.queryAll(By.css('.fci-lane-form .mat-spinner'));

      expect(component.isLoadingLanes).toBe(false);
      expect(laneSpinnerEl.length).toBe(0);
    });
  });

  describe('triggers', () => {
    beforeEach(() => {
      // Load Repos
      reposSubject.next(mockRepositoryList);
      fixture.detectChanges();
    });

    it('should show correct nightly trigger option name', () => {
      component.project.trigger_type = 'nightly';
      fixture.detectChanges();

      expect(triggerSelectEl.textContent).toBe('nightly');
    });

    it('should show correct nightly commit and PR option name', () => {
      component.project.trigger_type = 'commit';
      fixture.detectChanges();

      expect(triggerSelectEl.textContent).toBe('for every commit and PR');
    });

    it('should show time selection when trigger is nightly', () => {
      component.project.trigger_type = 'nightly';
      fixture.detectChanges();

      expect(fixture.debugElement.queryAll(By.css('.fci-hour-select')).length)
          .toBe(1);
      expect(fixture.debugElement.queryAll(By.css('.fci-am-pm-select')).length)
          .toBe(1);
    });

    it('should not show time selection when trigger is not nightly', () => {
      component.project.trigger_type = 'commit';
      fixture.detectChanges();

      expect(fixture.debugElement.queryAll(By.css('.fci-hour-select')).length)
          .toBe(0);
      expect(fixture.debugElement.queryAll(By.css('.fci-am-pm-select')).length)
          .toBe(0);
    });

    it('should set nightly time correctly', async(() => {
         component.project.trigger_type = 'nightly';
         fixture.detectChanges();

         const hourEl: HTMLElement =
             fixture.debugElement.query(By.css('.fci-hour-select'))
                 .nativeElement;
         const amPmEl: HTMLElement =
             fixture.debugElement.query(By.css('.fci-am-pm-select'))
                 .nativeElement;

         // I think this is needed to load the hour/amPm select in ngIf block
         fixture.whenStable().then(() => {
           fixture.detectChanges();
           expect(hourEl.textContent).toBe('12');
           expect(amPmEl.textContent).toBe('AM');

           component.timeSelectorData.hour = 2;
           component.timeSelectorData.isAm = false;
           fixture.detectChanges();

           expect(hourEl.textContent).toBe('2');
           expect(amPmEl.textContent).toBe('PM');
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
    });

    it('should add the project hour in military time when nightly trigger',
       () => {
         component.project.trigger_type = 'nightly';

         // 1PM or 13:00
         component.timeSelectorData.hour = 1;
         component.timeSelectorData.isAm = false;

         addProjectButtonEl.click();

         expect(component.project.hour).toBe(13);

         // Midnight or 0:00
         component.timeSelectorData.hour = 12;
         component.timeSelectorData.isAm = true;

         addProjectButtonEl.click();

         expect(component.project.hour).toBe(0);
       });

    it('should show spinner while adding project', () => {
      const spinnerEl = fixture.debugElement.query(By.css('.mat-spinner'));
      expect(fixture.debugElement.queryAll(By.css('.mat-spinner')).length)
          .toBe(0);

      addProjectButtonEl.click();
      fixture.detectChanges();

      expect(fixture.debugElement.queryAll(By.css('.mat-spinner')).length)
          .toBe(1);

      projectSubject.next(mockProject);
      fixture.detectChanges();

      expect(fixture.debugElement.queryAll(By.css('.mat-spinner')).length)
          .toBe(0);
    });

    it('should close dialog on success',
       () => {
           // TODO
       });
  });
});
