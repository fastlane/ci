import {HttpClientTestingModule, HttpTestingController} from '@angular/common/http/testing';
import {fakeAsync, TestBed, tick} from '@angular/core/testing';

import {BuildStatus} from '../common/constants';
import {mockLanesResponse} from '../common/test_helpers/mock_lane_data';
import {mockProjectListResponse, mockProjectResponse, mockProjectSummaryResponse} from '../common/test_helpers/mock_project_data';
import {mockRepositoryListResponse, mockRepositoryResponse} from '../common/test_helpers/mock_repository_data';
import {Lane} from '../models/lane';
import {Project} from '../models/project';
import {ProjectSummary} from '../models/project_summary';
import {Repository, RepositoryResponse} from '../models/repository';

import {AddProjectRequest, DataService} from './data.service';

const COMMIT_TRIGGER_PROJECT_REQUEST: AddProjectRequest = {
  lane: 'ios test',
  branch: 'master',
  repo_org: 'fastlane',
  repo_name: 'ci',
  project_name: 'new hot project',
  trigger_type: 'commit'
};

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

  describe('#getRepoLanes', () => {
    it('should return response mapped to Lane model', () => {
      let lanes: Lane[];
      dataService.getRepoLanes('some/repo', 'master')
          .subscribe((lanesResponse) => {
            lanes = lanesResponse;
          });

      const lanesRequest = mockHttp.expectOne(
          '/data/repos/lanes?repo_full_name=some%2Frepo&branch=master');
      lanesRequest.flush(mockLanesResponse);

      expect(lanes.length).toBe(2);
      expect(lanes[0].name).toBe('test');
      expect(lanes[0].platform).toBe('ios');
      expect(lanes[1].name).toBe('beta');
      expect(lanes[1].platform).toBe('android');
    });
  });

  describe('#addProject', () => {
    it('should add project with commit trigger', () => {
      let project: ProjectSummary;
      dataService.addProject(COMMIT_TRIGGER_PROJECT_REQUEST)
          .subscribe((projectRespone) => {
            project = projectRespone;
          });

      const projectsRequest = mockHttp.expectOne('/data/projects');
      expect(projectsRequest.request.body).toBe(COMMIT_TRIGGER_PROJECT_REQUEST);
      projectsRequest.flush(mockProjectSummaryResponse);

      expect(project.id).toBe('1');
      expect(project.name).toBe('the coolest project');
      expect(project.lane).toBe('ios test');
    });
  });

  describe('#getRepo', () => {
    it('should return response mapped to Repository model', () => {
      let repositories: Repository[];
      dataService.getRepos().subscribe((repositoryResponse) => {
        repositories = repositoryResponse;
      });

      const repositoriesRequest = mockHttp.expectOne('/data/repos');
      repositoriesRequest.flush(mockRepositoryListResponse);

      expect(repositories.length).toBe(3);
      expect(repositories[0].fullName).toBe('fastlane/ci');
      expect(repositories[2].url)
          .toBe('https://github.com/fastlane/onboarding');
    });
  });
});
