import {HttpClient} from '@angular/common/http';
import {Injectable} from '@angular/core';
import * as moment from 'moment';
import {Observable} from 'rxjs/Observable';
import {shareReplay, tap} from 'rxjs/operators';
import {LocalStorageKeys} from '../common/constants';

// Auth server is currently locally hosted.
const API_ROOT = '/api';

export interface LoginResponse {
  token: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

interface DecodedJwt {
  exp: number;   // Token Expiry date in seconds
  iat: number;   // Token Issue date in seconds
  iss: string;   // Token Issuer
  user: string;  // User ID
}

function getTokenExpiryDate(token: string): Date {
  const base64Url = token.split('.')[1];
  const base64 = base64Url.replace('-', '+').replace('_', '/');
  const decodedJwt: DecodedJwt = JSON.parse(window.atob(base64));

  // Need to convert from seconds to milliseconds
  return new Date(decodedJwt.exp * 1000);
}

@Injectable()
export class AuthService {
  constructor(private http: HttpClient) {}

  login(loginRequest: LoginRequest): Observable<LoginResponse> {
    const url = `${API_ROOT}/login`;
    return this.http.post<LoginResponse>(url, loginRequest)
        .pipe(tap(this.setSession), shareReplay());
  }

  // manage the expiry without having to make a request.
  private setSession(loginResponse: LoginResponse) {
    localStorage.setItem(LocalStorageKeys.AUTH_TOKEN, loginResponse.token);
  }

  logout(): void {
    localStorage.removeItem(LocalStorageKeys.AUTH_TOKEN);
  }

  token(): string {
    return localStorage.getItem(LocalStorageKeys.AUTH_TOKEN);
  }

  /** Checks if the user has a token and if the token is still valid */
  isLoggedIn(): boolean {
    return !!this.token() && getTokenExpiryDate(this.token()) > new Date(Date.now());
  }
}
