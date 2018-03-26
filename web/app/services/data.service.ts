import {HttpClient} from '@angular/common/http';
import {Injectable} from '@angular/core';
import {Observable} from 'rxjs/Observable';
import {map} from 'rxjs/operators';

import {Project, ProjectResponse} from '../models/project';

// Data server is currently locally hosted.
const HOSTNAME = '/data';

@Injectable()
export class DataService {
  constructor(private http: HttpClient) {}

  getProjects(): Observable<Project[]> {
    const url = `${HOSTNAME}/projects`;
    return this.http.get<ProjectResponse[]>(url).pipe(
        map((projects) => projects.map((project) => new Project(project))));
  }
}
