import {HttpClientTestingModule, HttpTestingController} from '@angular/common/http/testing';
import {fakeAsync, TestBed, tick} from '@angular/core/testing';

import {BuildStatus} from '../common/constants';

import {DataService} from './data.service';
import {mockProjectListResponse} from './test_helpers/mock_project_response';

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
    it('should return response mapped to Project model', () => {
      let projects;
      dataService.getProjects().subscribe((projectsRespone) => {
        projects = projectsRespone;
      });

      const projectsRequest = mockHttp.expectOne('/data/projects');
      projectsRequest.flush(mockProjectListResponse);

      expect(projects.length).toBe(3);
      expect(projects[0].name).toBe('the coolest project');
      expect(projects[0].lane).toBe('ios test');
      expect(projects[1].latestStatus).toBe(BuildStatus.SUCCESS);
      expect(projects[1].lane).toBe('this project is okay');
      expect(projects[2].latestDate).toBe('this project needs some work');
      expect(projects[2].latestStatus).toBe(BuildStatus.FAILED);
    });
  });
});
