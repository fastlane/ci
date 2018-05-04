import {CommonModule} from '@angular/common';
import {async, ComponentFixture, TestBed} from '@angular/core/testing';
import {FormsModule} from '@angular/forms';
import {MatButtonModule, MatDialogModule, MatIconModule, MatSelectModule} from '@angular/material';
import {MAT_DIALOG_DATA} from '@angular/material';
import {By} from '@angular/platform-browser';
import {Subject} from 'rxjs/Subject';

import {mockRepositoryList} from '../../common/test_helpers/mock_repository_data';
import {Project} from '../../models/project';
import {Repository} from '../../models/repository';
import {DataService} from '../../services/data.service';

import {AddProjectDialogComponent} from './add-project-dialog.component';

describe('AddProjectDialogComponent', () => {
  let component: AddProjectDialogComponent;
  let fixture: ComponentFixture<AddProjectDialogComponent>;
  let reposSubject: Subject<Repository[]>;
  let projectSubject: Subject<Project>;
  let dataService: jasmine.SpyObj<Partial<DataService>>;
  let projectNameEl: HTMLInputElement;
  let repoSelectEl: HTMLElement;
  let laneSelectEl: HTMLElement;
  let triggerSelectEl: HTMLElement;
  let addProjectButtonEl: HTMLButtonElement;

  beforeEach(async(() => {
    dataService = {
      addProject: jasmine.createSpy().and.returnValue(projectSubject)
    };
    reposSubject = new Subject<Repository[]>();
    projectSubject = new Subject<Project>();

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
            CommonModule, FormsModule
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
    reposSubject.next(mockRepositoryList);
    fixture.detectChanges();

    component.project.repo_name = 'fastlane/fastlane';
    fixture.detectChanges();

    expect(repoSelectEl.textContent).toBe('fastlane/fastlane');

    component.project.repo_name = 'fastlane/ci';
    fixture.detectChanges();

    expect(repoSelectEl.textContent).toBe('fastlane/ci');
  });

  it('should set lane option', () => {
    component.project.lane = 'ios beta';
    fixture.detectChanges();

    expect(laneSelectEl.textContent).toBe('ios beta');

    component.project.lane = 'ios test';
    fixture.detectChanges();

    expect(laneSelectEl.textContent).toBe('ios test');
  });

  describe('triggers', () => {
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

      expect(fixture.debugElement.query(By.css('.fci-hour-select')))
          .not.toBe(null);
      expect(fixture.debugElement.query(By.css('.fci-am-pm-select')))
          .not.toBe(null);
    });

    it('should not show time selection when trigger is not nightly', () => {
      component.project.trigger_type = 'commit';
      fixture.detectChanges();

      expect(fixture.debugElement.query(By.css('.fci-hour-select'))).toBe(null);
      expect(fixture.debugElement.query(By.css('.fci-am-pm-select')))
          .toBe(null);
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

    it('should show spinner while adding project',
       () => {
           // TODO
       });

    it('should close dialog on success',
       () => {
           // TODO
       });
  });
});
