import 'rxjs/add/operator/switchMap';

import {Location} from '@angular/common';
import {DebugElement} from '@angular/core';
import {async, ComponentFixture, fakeAsync, flush, TestBed, tick} from '@angular/core/testing';
import {MatCardModule, MatDialog, MatIconModule, MatProgressSpinnerModule, MatTableModule} from '@angular/material';
import {By} from '@angular/platform-browser';
import {ActivatedRoute, convertToParamMap} from '@angular/router';
import {RouterTestingModule} from '@angular/router/testing';
import {MomentModule} from 'ngx-moment';
import {Observable} from 'rxjs/Observable';
import {Subject} from 'rxjs/Subject';

import {StatusIconModule} from '../common/components/status-icon/status-icon.module';
import {ToolbarModule} from '../common/components/toolbar/toolbar.module';
import {DummyComponent} from '../common/test_helpers/dummy.component';
// tslint:disable-next-line:max-line-length
import {expectElementNotToExist, expectElementToExist, getAllElements, getElement, getElementText} from '../common/test_helpers/element_helper_functions';
import {mockBuildSummary_success} from '../common/test_helpers/mock_build_data';
import {getMockProject} from '../common/test_helpers/mock_project_data';
import {BuildSummary} from '../models/build_summary';
import {Project} from '../models/project';
import {SharedMaterialModule} from '../root/shared_material.module';
import {DataService} from '../services/data.service';

import {ProjectComponent} from './project.component';
import {SettingsDialogComponent} from './settings-dialog/settings-dialog.component';
import {SettingsDialogModule} from './settings-dialog/settings-dialog.modules';

describe('ProjectComponent', () => {
  let location: Location;
  let component: ProjectComponent;
  let fixture: ComponentFixture<ProjectComponent>;
  let fixtureEl: DebugElement;
  let dataService: jasmine.SpyObj<Partial<DataService>>;
  let projectSubject: Subject<Project>;
  let rebuildSummarySubject: Subject<BuildSummary>;
  let dialog: jasmine.SpyObj<Partial<MatDialog>>;

  beforeEach(async(() => {
    projectSubject = new Subject<Project>();
    rebuildSummarySubject = new Subject<BuildSummary>();
    dataService = {
      getProject:
          jasmine.createSpy().and.returnValue(projectSubject.asObservable()),
      rebuild: jasmine.createSpy().and.returnValue(
          rebuildSummarySubject.asObservable())
    };
    dialog = {open: jasmine.createSpy()};

    TestBed
        .configureTestingModule({
          imports: [
            StatusIconModule, MomentModule, ToolbarModule, MatCardModule,
            MatTableModule, MatProgressSpinnerModule, SettingsDialogModule,
            MatIconModule, RouterTestingModule.withRoutes([
              {
                path: 'project/:projectId/build/:buildId',
                component: DummyComponent
              },
              {
                path: '404',
                component: DummyComponent
              }
            ])
          ],
          declarations: [ProjectComponent, DummyComponent],
          providers: [
            {provide: DataService, useValue: dataService}, {
              provide: ActivatedRoute,
              useValue:
                  {paramMap: Observable.of(convertToParamMap({id: '123'}))}
            },
            {provide: MatDialog, useValue: dialog}
          ],
        })
        .compileComponents();

    fixture = TestBed.createComponent(ProjectComponent);
    fixtureEl = fixture.debugElement;
    component = fixture.componentInstance;

    location = TestBed.get(Location);
  }));

  describe('Unit tests', () => {
    it('should load project', () => {
      expect(component.isLoading).toBe(true);

      fixture.detectChanges();  // onInit()
      expect(dataService.getProject).toHaveBeenCalledWith('123');
      projectSubject.next(getMockProject());  // Resolve observable

      expect(component.isLoading).toBe(false);
      expect(component.project.id).toBe('12');
      expect(component.project.name).toBe('the most coolest project');
      expect(component.project.builds.length).toBe(2);
      expect(component.project.builds[0].sha).toBe('asdfshzdggfdhdfh4');
    });

    it('should redirect if API returns an error', fakeAsync(() => {
      fixture.detectChanges();
      expect(dataService.getProject).toHaveBeenCalledWith('123');

      projectSubject.error({});
      tick();

      expect(location.path()).toBe('/404');
    }));

    it('should update breadcrumbs after loading project', () => {
      fixture.detectChanges();  // onInit()
      expect(component.breadcrumbs[1].hint).toBe('Project');
      expect(component.breadcrumbs[1].label).toBeUndefined();

      projectSubject.next(getMockProject());  // Resolve observable

      expect(component.breadcrumbs[1].label).toBe('the most coolest project');
    });

    it('#rebuild should send rebuild request', () => {
      fixture.detectChanges();                // onInit()
      projectSubject.next(getMockProject());  // Resolve observable

      component.rebuild(new Event('click'), getMockProject().builds[0]);
      expect(dataService.rebuild).toHaveBeenCalledWith('12', 2);
    });

    it('#rebuild should add new Build Summary to table data', fakeAsync(() => {
         fixture.detectChanges();                // onInit()
         projectSubject.next(getMockProject());  // Resolve observable
         flush();
         fixture.detectChanges();
         flush();

         component.rebuild(new Event('click'), getMockProject().builds[0]);

         expect(component.project.builds.length).toBe(2);
         rebuildSummarySubject.next(mockBuildSummary_success);

         expect(component.project.builds.length).toBe(3);
       }));
  });

  describe('Shallow Tests', () => {
    describe('Project not loaded', () => {
      beforeEach(() => {
        fixture.detectChanges();  // onInit()
      });

      it('should not show project title', () => {
        expectElementNotToExist(fixtureEl, '.fci-project-header');
      });

      it('table should not show loading spinner', () => {
        expectElementToExist(
            fixtureEl, '.fci-build-table .fci-loading-spinner');
      });

      it('details card should not show loading spinner', () => {
        expectElementToExist(
            fixtureEl, '.fci-project-details .fci-loading-spinner');
      });

      it('should open settings dialog when settings gear is clicked', () => {
        fixture.debugElement.query(By.css('.fci-settings-button'))
            .nativeElement.click();
        expect(dialog.open).toHaveBeenCalledWith(SettingsDialogComponent, {
          panelClass: 'fci-dialog',
          width: '1028px',
          data: {project: this.project},
        });
      });
    });

    describe('Project loaded', () => {
      beforeEach(fakeAsync(() => {
        fixture.detectChanges();                // onInit()
        projectSubject.next(getMockProject());  // Resolve observable
        flush();

        fixture.detectChanges();
        flush();
      }));

      it('should have toolbar with breadcrumbs', () => {
        // toolbar exists
        expect(getAllElements(fixtureEl, '.fci-crumb').length).toBe(2);

        expect(component.breadcrumbs[0].label).toBe('Dashboard');
        expect(component.breadcrumbs[0].url).toBe('/');
      });

      it('should have project title', () => {
        expect(getElementText(fixtureEl, '.fci-project-header'))
            .toBe('the most coolest project');
      });

      describe('table', () => {
        let rowEls: DebugElement[];
        beforeEach(() => {
          rowEls = getAllElements(fixtureEl, '.mat-row');
          expect(rowEls.length).toBe(2);
        });

        it('should not show loading spinner', () => {
          expectElementNotToExist(
              fixtureEl, '.fci-build-table .fci-loading-spinner');
        });

        it('should have status icon', () => {
          expect(
              getElementText(rowEls[0], '.mat-column-number .fci-status-icon'))
              .toBe('check_circle');
          expect(
              getElementText(rowEls[1], '.mat-column-number .fci-status-icon'))
              .toBe('cancel');
        });

        it('should have build number', () => {
          expect(getElementText(rowEls[0], '.mat-column-number span'))
              .toBe('2');
          expect(getElementText(rowEls[1], '.mat-column-number span'))
              .toBe('1');
        });

        it('should have duration', () => {
          expect(getElementText(rowEls[0], '.mat-column-duration'))
              .toBe('3 days');
        });

        it('should have branch', () => {
          expect(getElementText(rowEls[0], '.mat-column-branch'))
              .toBe('master');
        });

        it('should have sha link', () => {
          expect(getElementText(rowEls[0], '.mat-column-sha a')).toBe('asdfsh');
        });

        it('should go to build when clicked', fakeAsync(() => {
          rowEls[0].nativeElement.click();
          tick();
          expect(location.path()).toBe('/project/12/build/2');
        }));

        it('should not show rebuild button on successful builds', () => {
          // First row is successful build
          expectElementNotToExist(
              rowEls[0], '.mat-column-sha .fci-button-visible');
        });

        it('should show rebuild button on failed builds', () => {
          // Second row is failed build
          expectElementToExist(
              rowEls[1], '.mat-column-sha .fci-button-visible');
        });

        it('should rebuild when rebuild button is clicked', () => {
          const buttonEl =
              getElement(rowEls[1], '.mat-column-sha .fci-button-visible');

          buttonEl.nativeElement.click();
          expect(dataService.rebuild).toHaveBeenCalledWith('12', 1);
        });

        it('should add new row after rebuild is complete', () => {
          const buttonEl =
              getElement(rowEls[1], '.mat-column-sha .fci-button-visible');

          buttonEl.nativeElement.click();
          rebuildSummarySubject.next(mockBuildSummary_success);
          fixture.detectChanges();

          expect(getAllElements(fixtureEl, '.mat-row').length).toBe(3);
        });
      });

      describe('details card', () => {
        let cardEl: DebugElement;
        let headerEls: DebugElement[];
        let contentsEls: DebugElement[];

        beforeEach(() => {
          cardEl = getElement(fixtureEl, '.fci-project-details');
          headerEls = getAllElements(cardEl, 'h5');
          contentsEls = getAllElements(cardEl, 'div');
        });

        it('should not show loading spinner', () => {
          expectElementNotToExist(cardEl, '.fci-loading-spinner');
        });

        it('should show Repo name', () => {
          expect(getElementText(headerEls[0])).toBe('REPO');
          expect(getElementText(contentsEls[0])).toBe('fastlane/TacoRocat');
        });

        it('should show lane', () => {
          expect(getElementText(headerEls[1])).toBe('LANE');
          expect(getElementText(contentsEls[1])).toBe('ios test');
        });

        it('should show last successful build number', () => {
          expect(getElementText(headerEls[2])).toBe('LAST SUCCESSFUL BUILD');
          expect(getElementText(contentsEls[2])).toBe('2');
        });

        it('should show last failed build number', () => {
          expect(getElementText(headerEls[3])).toBe('LAST FAILED BUILD');
          expect(getElementText(contentsEls[3])).toBe('1');
        });
      });
    });
  });
});
