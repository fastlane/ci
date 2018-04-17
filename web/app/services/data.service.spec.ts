import {HttpClientTestingModule, HttpTestingController} from '@angular/common/http/testing';
import {fakeAsync, TestBed, tick} from '@angular/core/testing';

import {BuildStatus} from '../common/constants';
import {Project} from '../models/project';
import {ProjectSummary} from '../models/project_summary';

import {DataService} from './data.service';
import {mockProjectListResponse, mockProjectResponse} from './test_helpers/mock_project_response';

describe('DataService', () => {
  let mockHttp: HttpTestingController;
  let dataService: DataService;

  beforeEach(() => {
    TestBed.configureTestingModule(
        {imports: [HttpClientTestingModule], providers: [DataService]});

    mockHttp = TestBed.get(HttpTestingController);
    dataService = TestBed.get(DataService);
  });

  describe('#getProjects', () => {
    it('should return response mapped to Project Summary model', () => {
      let projects: ProjectSummary[];
      dataService.getProjects().subscribe((projectsRespone) => {
        projects = projectsRespone;
      });

      const projectsRequest = mockHttp.expectOne('/data/projects');
      projectsRequest.flush(mockProjectListResponse);

      expect(projects.length).toBe(4);
      expect(projects[0].name).toBe('the coolest project');
      expect(projects[0].lane).toBe('ios test');
      expect(projects[1].latestStatus).toBe(BuildStatus.SUCCESS);
      expect(projects[1].lane).toBe('ios release');
      expect(projects[2].latestDate.getTime())
          .toBe(1522883518000);  // 2018-04-04 16:11:58 -0700
      expect(projects[2].latestStatus).toBe(BuildStatus.FAILED);
    });
  });

  describe('#getProject', () => {
    it('should return response mapped to Project model with builds', () => {
      let project: Project;
      dataService.getProject('some-id').subscribe((projectRespone) => {
        project = projectRespone;
      });

      const projectsRequest = mockHttp.expectOne('/data/projects/some-id');
      projectsRequest.flush(mockProjectResponse);

      expect(project.id).toBe('12');
      expect(project.builds.length).toBe(2);
      expect(project.builds[0].status).toBe(BuildStatus.SUCCESS);
      expect(project.builds[1].status).toBe(BuildStatus.FAILED);
    });
  });
});
