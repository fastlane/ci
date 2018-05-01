import {HttpClient} from '@angular/common/http';
import {Injectable} from '@angular/core';
import * as moment from 'moment';
import {Observable} from 'rxjs/Observable';
import {shareReplay, tap} from 'rxjs/operators';
import {LocalStorageKeys} from '../common/constants';

// Auth server is currently locally hosted.
const HOSTNAME = '/data';

export interface LoginResponse {
  token: string;
}

export interface LoginRequest {
  username: string;
  password: string;
}

@Injectable()
export class AuthService {
  constructor(private http: HttpClient) {}

  login(loginRequest: LoginRequest): Observable<LoginResponse> {
    const url = `${HOSTNAME}/login`;
    return this.http.post<LoginResponse>(url, loginRequest)
        .pipe(tap(this.setSession), shareReplay());
  }

  // TODO: Store the expiry time alongside the token, so the client can
  // manage the expiry without having to make a request.
  private setSession(loginResponse: LoginResponse) {
    localStorage.setItem(LocalStorageKeys.AUTH_TOKEN, loginResponse.token);
  }

  logout(): void {
    localStorage.removeItem(LocalStorageKeys.AUTH_TOKEN);
  }

  isLoggedIn(): boolean {
    // TODO: check expiration once we preserve the expiry time
    return !!localStorage.getItem(LocalStorageKeys.AUTH_TOKEN);
  }

  getExpiration(): void {
    // TODO: one we preserve the expiry time
  }
}
