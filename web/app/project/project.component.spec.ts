import 'rxjs/add/operator/switchMap';

import {Location} from '@angular/common';
import {DebugElement} from '@angular/core';
import {async, ComponentFixture, fakeAsync, flush, TestBed, tick} from '@angular/core/testing';
import {MatCardModule, MatProgressSpinnerModule, MatTableModule} from '@angular/material';
import {By} from '@angular/platform-browser';
import {ActivatedRoute, convertToParamMap} from '@angular/router';
import {RouterTestingModule} from '@angular/router/testing';
import {MomentModule} from 'ngx-moment';
import {Observable} from 'rxjs/Observable';
import {Subject} from 'rxjs/Subject';

import {StatusIconModule} from '../common/components/status-icon/status-icon.module';
import {ToolbarModule} from '../common/components/toolbar/toolbar.module';
import {DummyComponent} from '../common/test_helpers/dummy.component';
import {mockBuildSummary_success} from '../common/test_helpers/mock_build_data';
import {getMockProject} from '../common/test_helpers/mock_project_data';
import {BuildSummary} from '../models/build_summary';
import {Project} from '../models/project';
import {SharedMaterialModule} from '../root/shared_material.module';
import {DataService} from '../services/data.service';

import {ProjectComponent} from './project.component';

describe('ProjectComponent', () => {
  let component: ProjectComponent;
  let fixture: ComponentFixture<ProjectComponent>;
  let dataService: jasmine.SpyObj<Partial<DataService>>;
  let projectSubject: Subject<Project>;
  let rebuildSummarySubject: Subject<BuildSummary>;

  beforeEach(async(() => {
    projectSubject = new Subject<Project>();
    rebuildSummarySubject = new Subject<BuildSummary>();
    dataService = {
      getProject:
          jasmine.createSpy().and.returnValue(projectSubject.asObservable()),
      rebuild: jasmine.createSpy().and.returnValue(
          rebuildSummarySubject.asObservable())
    };

    TestBed
        .configureTestingModule({
          imports: [
            StatusIconModule, MomentModule, ToolbarModule, MatCardModule,
            MatTableModule, MatProgressSpinnerModule,
            RouterTestingModule.withRoutes([
              {
                path: 'project/:projectId/build/:buildId',
                component: DummyComponent
              },
            ])
          ],
          declarations: [ProjectComponent, DummyComponent],
          providers: [
            {provide: DataService, useValue: dataService}, {
              provide: ActivatedRoute,
              useValue:
                  {paramMap: Observable.of(convertToParamMap({id: '123'}))}
            }
          ],
        })
        .compileComponents();

    fixture = TestBed.createComponent(ProjectComponent);
    component = fixture.componentInstance;
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
        expect(
            fixture.debugElement.queryAll(By.css('.fci-project-header')).length)
            .toBe(0);
      });

      it('table should not show loading spinner', () => {
        expect(fixture.debugElement
                   .queryAll(By.css('.fci-build-table .fci-loading-spinner'))
                   .length)
            .toBe(1);
      });

      it('details card should not show loading spinner', () => {
        expect(
            fixture.debugElement
                .queryAll(By.css('.fci-project-details .fci-loading-spinner'))
                .length)
            .toBe(1);
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
        expect(fixture.debugElement.queryAll(By.css('.fci-crumb')).length)
            .toBe(2);

        expect(component.breadcrumbs[0].label).toBe('Dashboard');
        expect(component.breadcrumbs[0].url).toBe('/');
      });

      it('should have project title', () => {
        expect(fixture.debugElement.query(By.css('.fci-project-header'))
                   .nativeElement.innerText)
            .toBe('the most coolest project');
      });

      describe('table', () => {
        let rowEls: DebugElement[];
        beforeEach(() => {
          rowEls = fixture.debugElement.queryAll(By.css('.mat-row'));
          expect(rowEls.length).toBe(2);
        });

        it('should not show loading spinner', () => {
          expect(fixture.debugElement
                     .queryAll(By.css('.fci-build-table .fci-loading-spinner'))
                     .length)
              .toBe(0);
        });

        it('should have status icon', () => {
          expect(rowEls[0]
                     .query(By.css('.mat-column-number .fci-status-icon'))
                     .nativeElement.innerText)
              .toBe('check_circle');
          expect(rowEls[1]
                     .query(By.css('.mat-column-number .fci-status-icon'))
                     .nativeElement.innerText)
              .toBe('cancel');
        });

        it('should have build number', () => {
          expect(rowEls[0]
                     .query(By.css('.mat-column-number span'))
                     .nativeElement.innerText)
              .toBe('2');
          expect(rowEls[1]
                     .query(By.css('.mat-column-number span'))
                     .nativeElement.innerText)
              .toBe('1');
        });

        it('should have duration', () => {
          expect(rowEls[0]
                     .query(By.css('.mat-column-duration'))
                     .nativeElement.innerText)
              .toBe('3 days');
        });

        it('should have branch', () => {
          expect(rowEls[0]
                     .query(By.css('.mat-column-branch'))
                     .nativeElement.innerText)
              .toBe('master');
        });

        it('should have sha link', () => {
          expect(rowEls[0]
                     .query(By.css('.mat-column-sha a'))
                     .nativeElement.innerText)
              .toBe('asdfsh');
        });

        it('should go to build when clicked', fakeAsync(() => {
             const location = TestBed.get(Location);
             rowEls[0].nativeElement.click();
             tick();
             expect(location.path()).toBe('/project/12/build/2');
           }));

        it('should not show rebuild button on successful builds', () => {
          // First row is successful build
          expect(rowEls[0]
                     .queryAll(By.css('.mat-column-sha .fci-button-visible'))
                     .length)
              .toBe(0);
        });

        it('should show rebuild button on failed builds', () => {
          // Second row is failed build
          expect(rowEls[1]
                     .queryAll(By.css('.mat-column-sha .fci-button-visible'))
                     .length)
              .toBe(1);
        });

        it('should rebuild when rebuild button is clicked', () => {
          const buttonEl =
              rowEls[1].query(By.css('.mat-column-sha .fci-button-visible'));

          buttonEl.nativeElement.click();
          expect(dataService.rebuild).toHaveBeenCalledWith('12', 1);
        });

        it('should add new row after rebuild is complete', () => {
          const buttonEl =
              rowEls[1].query(By.css('.mat-column-sha .fci-button-visible'));

          buttonEl.nativeElement.click();
          rebuildSummarySubject.next(mockBuildSummary_success);
          fixture.detectChanges();

          expect(fixture.debugElement.queryAll(By.css('.mat-row')).length)
              .toBe(3);
        });
      });

      describe('details card', () => {
        let cardEl: DebugElement;
        let headerEls: DebugElement[];
        let contentsEls: DebugElement[];

        beforeEach(() => {
          cardEl = fixture.debugElement.query(By.css('.fci-project-details'));
          headerEls = cardEl.queryAll(By.css('h5'));
          contentsEls = cardEl.queryAll(By.css('div'));
        });

        it('should not show loading spinner', () => {
          expect(cardEl.queryAll(By.css('.fci-loading-spinner')).length)
              .toBe(0);
        });

        it('should show Repo name', () => {
          expect(headerEls[0].nativeElement.innerText).toBe('REPO');
          expect(contentsEls[0].nativeElement.innerText)
              .toBe('fastlane/TacoRocat');
        });

        it('should show lane', () => {
          expect(headerEls[1].nativeElement.innerText).toBe('LANE');
          expect(contentsEls[1].nativeElement.innerText).toBe('ios test');
        });

        it('should show last successful build number', () => {
          expect(headerEls[2].nativeElement.innerText)
              .toBe('LAST SUCCESSFUL BUILD');
          expect(contentsEls[2].nativeElement.innerText).toBe('2');
        });

        it('should show last failed build number', () => {
          expect(headerEls[3].nativeElement.innerText)
              .toBe('LAST FAILED BUILD');
          expect(contentsEls[3].nativeElement.innerText).toBe('1');
        });
      });
    });
  });
});
