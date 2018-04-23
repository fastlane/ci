import {HttpClient} from '@angular/common/http';
import {Injectable} from '@angular/core';
import {Observable} from 'rxjs/Observable';
import {map} from 'rxjs/operators';

import {Project, ProjectResponse} from '../models/project';
import {ProjectSummary, ProjectSummaryResponse} from '../models/project_summary';
import {Repository, RepositoryResponse} from '../models/repository';

// Data server is currently locally hosted.
const HOSTNAME = '/data';

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

  getRepos(): Observable<Repository[]> {
    const url = `${HOSTNAME}/repos`;
    return this.http.get<RepositoryResponse[]>(url).pipe(map(
      (repos) => repos.map((repo) => new Repository(repo))));
  }
}
