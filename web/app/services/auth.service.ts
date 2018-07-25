import {HttpClient} from '@angular/common/http';
import {Injectable} from '@angular/core';
import * as moment from 'moment';
import {Observable} from 'rxjs/Observable';
import {shareReplay, tap} from 'rxjs/operators';
import {LocalStorageKeys} from '../common/constants';
import {GitHubScope} from '../common/types';

// Auth server is currently locally hosted.
const API_ROOT = '/api';
const DEFAULT_SCOPES: GitHubScope[] = ['repo'];
export interface LoginResponse {
  oauth_key: string;
}

@Injectable()
export class AuthService {
  constructor(private http: HttpClient) {}

  login(scopes: GitHubScope[] = DEFAULT_SCOPES): Observable<LoginResponse> {
    // TODO: github UI workflow
    const code = 'placeholder';
    const url = `${API_ROOT}/user/oauth?code=${code}`;
    return this.http.get<LoginResponse>(url).pipe(
        tap(this.setSession), shareReplay());
  }

  // preserve the token in the local storage
  private setSession(loginResponse: LoginResponse) {
    localStorage.setItem(LocalStorageKeys.AUTH_TOKEN, loginResponse.oauth_key);
  }

  logout(): void {
    localStorage.removeItem(LocalStorageKeys.AUTH_TOKEN);
  }

  /** Checks if the user has a token */
  isLoggedIn(): boolean {
    return !!localStorage.getItem(LocalStorageKeys.AUTH_TOKEN);
  }
}
