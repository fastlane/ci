import 'rxjs/add/operator/switchMap';

import {async, ComponentFixture, TestBed} from '@angular/core/testing';
import {By} from '@angular/platform-browser';
import {ActivatedRoute, convertToParamMap} from '@angular/router';
import {RouterTestingModule} from '@angular/router/testing';
import {MomentModule} from 'ngx-moment';
import {Observable} from 'rxjs/Observable';
import {Subject} from 'rxjs/Subject';

import {CommonComponentsModule} from '../common/components/common-components.module';
import {ToolbarModule} from '../common/components/toolbar/toolbar.module';
import {mockProject} from '../common/test_helpers/mock_project_data';
import {Project} from '../models/project';
import {DataService} from '../services/data.service';
import {SharedMaterialModule} from '../shared_material.module';

import {ProjectComponent} from './project.component';

describe('ProjectComponent', () => {
  let component: ProjectComponent;
  let fixture: ComponentFixture<ProjectComponent>;
  let dataService: jasmine.SpyObj<Partial<DataService>>;
  let projectSubject: Subject<Project>;

  beforeEach(async(() => {
    projectSubject = new Subject<Project>();
    dataService = {
      getProject:
          jasmine.createSpy().and.returnValue(projectSubject.asObservable())
    };

    TestBed
        .configureTestingModule({
          imports: [
            CommonComponentsModule, SharedMaterialModule, MomentModule,
            ToolbarModule, RouterTestingModule
          ],
          declarations: [
            ProjectComponent,
          ],
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

  it('should load project', () => {
    expect(component.isLoading).toBe(true);

    fixture.detectChanges();  // onInit()
    expect(dataService.getProject).toHaveBeenCalledWith('123');
    projectSubject.next(mockProject);  // Resolve observable

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

    projectSubject.next(mockProject);  // Resolve observable

    expect(component.breadcrumbs[1].label).toBe('the most coolest project');
  });

  it('should have toolbar with breadcrumbs', () => {
    fixture.detectChanges();  // onInit()

    console.log(fixture.debugElement.query(By.css('.fci-crumb')));
    // toolbar exists
    expect(fixture.debugElement.queryAll(By.css('.fci-crumb')).length).toBe(2);

    expect(component.breadcrumbs[0].label).toBe('Dashboard');
    expect(component.breadcrumbs[0].url).toBe('/');
  });
});
