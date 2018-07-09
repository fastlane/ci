import 'rxjs/add/observable/of';

import {DebugElement} from '@angular/core';
import {async, ComponentFixture, fakeAsync, TestBed, tick} from '@angular/core/testing';
import {MatDialog, MatDialogModule} from '@angular/material';
import {By} from '@angular/platform-browser';
import {RouterModule} from '@angular/router';
import {RouterTestingModule} from '@angular/router/testing';
import {MomentModule} from 'ngx-moment';
import {Observable} from 'rxjs/Observable';
import {Subject} from 'rxjs/Subject';

import {StatusIconModule} from '../common/components/status-icon/status-icon.module';
import {BuildStatus} from '../common/constants';
import {getAllElements, getElement, getElementText} from '../common/test_helpers/element_helper_functions';
import {mockProjectSummary, mockProjectSummaryList} from '../common/test_helpers/mock_project_data';
import {ProjectSummary} from '../models/project_summary';
import {SharedMaterialModule} from '../root/shared_material.module';
import {DataService} from '../services/data.service';

import {DashboardComponent} from './dashboard.component';

describe('DashboardComponent', () => {
  let component: DashboardComponent;
  let fixture: ComponentFixture<DashboardComponent>;
  let fixtureEl: DebugElement;
  let dataService: jasmine.SpyObj<Partial<DataService>>;
  let dialog: jasmine.SpyObj<Partial<MatDialog>>;
  let projectListSubject: Subject<ProjectSummary[]>;
  let projectAddedSubject: Subject<ProjectSummary>;

  beforeEach(() => {
    projectListSubject = new Subject<ProjectSummary[]>();
    projectAddedSubject = new Subject<ProjectSummary>();

    dataService = {
      getProjects: jasmine.createSpy().and.returnValue(
          projectListSubject.asObservable()),
      getRepos: jasmine.createSpy()
    };

    dialog = {
      open: jasmine.createSpy().and.returnValue({
        componentInstance: {projectAdded: projectAddedSubject.asObservable()}
      })
    };

    TestBed
        .configureTestingModule({
          imports: [
            SharedMaterialModule,
            StatusIconModule,
            MomentModule,
            RouterModule,
            RouterTestingModule,
          ],
          declarations: [
            DashboardComponent,
          ],
          providers: [
            {provide: DataService, useValue: dataService},
            {provide: MatDialog, useValue: dialog}
          ],
        })
        .compileComponents();

    fixture = TestBed.createComponent(DashboardComponent);
    fixtureEl = fixture.debugElement;
    component = fixture.componentInstance;
  });

  describe('intitliazation', () => {
    it('should load project summaries', () => {
      expect(component.isLoading).toBe(true);

      projectListSubject.next(mockProjectSummaryList);  // Resolve observable

      expect(component.isLoading).toBe(false);
      expect(component.projects.length).toBe(4);
      expect(component.projects[0].id).toBe('1');
      expect(component.projects[0].name).toBe('the coolest project');
      expect(component.projects[1].latestStatus).toBe(BuildStatus.SUCCESS);
      expect(component.projects[2].latestStatus).toBe(BuildStatus.FAILED);
      expect(component.projects[3].latestDate).toBeUndefined();
      expect(component.projects[3].latestStatus).toBeUndefined();
    });
  });

  describe('after intitliazation', () => {
    beforeEach(() => {
      projectListSubject.next(mockProjectSummaryList);  // Resolve observable
      fixture.detectChanges();
    });

    it('should add new project to project table', () => {
      let tableRowsEl = getAllElements(fixtureEl, '.mat-row');
      expect(tableRowsEl.length).toBe(4);

      component.openAddProjectDialog();
      projectAddedSubject.next(mockProjectSummary);
      fixture.detectChanges();

      tableRowsEl = getAllElements(fixtureEl, '.mat-row');
      expect(tableRowsEl.length).toBe(5);
      expect(getElementText(tableRowsEl[4])).toContain('the coolest project');
    });

    it('should open add project dialog when new project is clicked', () => {
      getElement(fixtureEl, '.fci-dashboard-welcome button')
          .nativeElement.click();
      expect(dialog.open).toHaveBeenCalled();
    });
  });
});
