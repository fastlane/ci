import 'rxjs/add/observable/of';

import {HttpClient} from '@angular/common/http';
import {Injectable} from '@angular/core';
import * as moment from 'moment';
import {Observable} from 'rxjs/Observable';
import {Observer} from 'rxjs/Observer';
import {shareReplay, tap} from 'rxjs/operators';
import {Subscriber} from 'rxjs/Subscriber';

import {OAuthWebFlowPostMessage} from '../auth/auth.component';
import {LocalStorageKeys} from '../common/constants';
import {GitHubScope} from '../common/types';

import {WindowService} from './window.service';

// Auth server is currently locally hosted.
const API_ROOT = '/api/auth';
const DEFAULT_SCOPES: GitHubScope[] = ['repo'];

export interface AuthResponse {
  token: string;
}

export interface ClientIdResponse {
  id: string;
}

function getGitHubOAuthWebFlowUrl(
    clientId: string, scopes: GitHubScope[], redirectUri: string) {
  const scope = scopes.join(',');
  return 'https://github.com/login/oauth/authorize?' +
      `client_id=${clientId}&scope=${scope}&redirect_uri=${redirectUri}`;
}

@Injectable()
export class AuthService {
  constructor(
      private readonly http: HttpClient,
      private readonly windowService: WindowService) {}

  authorize(scopes: GitHubScope[] = DEFAULT_SCOPES): Observable<void> {
    // Window needs to be created immediately or it will be blocked by pop-up
    // blockers
    const newWindow = this.windowService.nativeWindow.open('', '_blank');

    return new Observable<void>((authObserver) => {
      this.redirectWindowToGitHubOAuth(newWindow, scopes, authObserver);
      this.listenForOAuthWindowFlowCompletion(authObserver);
    });
  }

  private listenForOAuthWindowFlowCompletion(observer: Subscriber<void>) {
    this.windowService.nativeWindow.addEventListener('message', (event) => {
      if (event.origin !== this.windowService.nativeWindow.location.origin) {
        // not our message
        return;
      }

      const code = (event.data as OAuthWebFlowPostMessage).code;
      const url = `${API_ROOT}/github?code=${code}`;
      this.http.get<AuthResponse>(url)
          .pipe(tap(this.saveAuthTokenToSession), shareReplay())
          .subscribe(
              () => {
                observer.next();
              },
              (error) => {
                observer.error(error);
              });
    });
  }

  private redirectWindowToGitHubOAuth(
      window: Window, scopes: GitHubScope[], observer: Subscriber<void>) {
    this.getClientId().subscribe(
        (clientId) => {
          // TODO: Need a way to pull this from the angular router
          const redirectUri = this.windowService.getExternalUrl('/auth/github');

          // Start the oauth web flow in the new window
          window.location.href =
              getGitHubOAuthWebFlowUrl(clientId, scopes, redirectUri);
        },
        (error) => {
          observer.error(error);
        });
  }

  // preserve the token in the local storage
  private saveAuthTokenToSession(authResponse: AuthResponse) {
    localStorage.setItem(LocalStorageKeys.AUTH_TOKEN, authResponse.token);
  }

  // preserve the token in the local storage
  private saveClientIdToSession(clientIdResponse: ClientIdResponse) {
    localStorage.setItem(LocalStorageKeys.OAUTH_CLIENT_ID, clientIdResponse.id);
  }

  private getClientId(): Observable<string> {
    const url = `${API_ROOT}/client_id`;
    const savedClientId =
        localStorage.getItem(LocalStorageKeys.OAUTH_CLIENT_ID);

    if (savedClientId) {
      return Observable.of(savedClientId);
    } else {
      return this.http.get<ClientIdResponse>(url)
          .pipe(tap(this.saveClientIdToSession), shareReplay())
          .map((clientIdResponse: ClientIdResponse) => clientIdResponse.id);
    }
  }

  logout(): void {
    localStorage.removeItem(LocalStorageKeys.AUTH_TOKEN);
  }

  /** Checks if the user has a token */
  isLoggedIn(): boolean {
    return !!localStorage.getItem(LocalStorageKeys.AUTH_TOKEN);
  }
}
