import {HttpClient} from '@angular/common/http';
import {Injectable} from '@angular/core';
import {Observable} from 'rxjs/Observable';
import {map} from 'rxjs/operators';

import {ProjectSummary, ProjectSummaryResponse} from '../models/project_summary';

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
}
