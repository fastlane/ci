import {HttpClient} from '@angular/common/http';
import {Injectable} from '@angular/core';
import {Observable} from 'rxjs/Observable';
import {map} from 'rxjs/operators';

import {UserDetails} from '../common/types';
import {Build, BuildLogLine, BuildResponse} from '../models/build';
import {BuildSummary, BuildSummaryResponse} from '../models/build_summary';
import {Lane, LaneResponse} from '../models/lane';
import {Project, ProjectResponse} from '../models/project';
import {ProjectSummary, ProjectSummaryResponse} from '../models/project_summary';
import {Repository, RepositoryResponse} from '../models/repository';

// Data server is currently locally hosted.
const HOSTNAME = '/data';

export interface AddProjectRequest {
  lane: string;
  repo_org: string;
  repo_name: string;
  branch: string;
  project_name: string;
  trigger_type: 'commit'|'nightly';
  hour?: number;
  minute?: number;
}

@Injectable()
export class DataService {
  constructor(private http: HttpClient) {}

  getProjects(): Observable<ProjectSummary[]> {
    const url = `${HOSTNAME}/projects`;
    return this.http.get<ProjectSummaryResponse[]>(url).pipe(map(
        (projects) => projects.map((project) => new ProjectSummary(project))));
  }

  getProject(id: string): Observable<Project> {
    const url = `${HOSTNAME}/projects/${id}`;
    return this.http.get<ProjectResponse>(url).pipe(
        map((project) => new Project(project)));
  }

  getBuild(projectId: string, buildNumber: number): Observable<Build> {
    const url = `${HOSTNAME}/projects/${projectId}/build/${buildNumber}`;
    return this.http.get<BuildResponse>(url).pipe(
        map((build) => new Build(build)));
  }

  getBuildLogs(projectId: string, buildNumber: number):
      Observable<BuildLogLine[]> {
    const url = `${HOSTNAME}/projects/${projectId}/build/${buildNumber}/logs`;
    return this.http.get<BuildLogLine[]>(url);
  }

  getUserDetails(apiToken: string): Observable<UserDetails> {
    const url =
        `${HOSTNAME}/repos/user_details?token=${encodeURIComponent(apiToken)}`;
    return this.http.get<UserDetails>(url);
  }

  rebuild(projectId: string, buildNumber: number): Observable<BuildSummary> {
    const url =
        `${HOSTNAME}/projects/${projectId}/build/${buildNumber}/rebuild`;
    return this.http.post<BuildSummaryResponse>(url, {}).pipe(
        map((build) => new BuildSummary(build)));
  }

  getRepoLanes(repoFullName: string, branch: string): Observable<Lane[]> {
    const queryParams = `repo_full_name=${
        encodeURIComponent(repoFullName)}&branch=${encodeURIComponent(branch)}`;
    const url = `${HOSTNAME}/repos/lanes?${queryParams}`;
    return this.http.get<LaneResponse[]>(url).pipe(
        map((lanes) => lanes.map((lane) => new Lane(lane))));
  }

  addProject(request: AddProjectRequest): Observable<ProjectSummary> {
    const url = `${HOSTNAME}/projects`;
    return this.http.post<ProjectSummaryResponse>(url, request)
        .pipe(map((project) => new ProjectSummary(project)));
  }

  getRepos(): Observable<Repository[]> {
    const url = `${HOSTNAME}/repos`;
    return this.http.get<RepositoryResponse[]>(url).pipe(
        map((repos) => repos.map((repo) => new Repository(repo))));
  }

  isServerConfigured(): Observable<boolean> {
    const url = `${HOSTNAME}/setup/configured`;
    return this.http.get<boolean>(url);
  }
}
