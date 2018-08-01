import 'rxjs/add/observable/combineLatest';

import {Component, OnInit} from '@angular/core';
import {ActivatedRoute, Params, Router, UrlMatchResult, UrlSegment} from '@angular/router';
import {Observable} from 'rxjs/Observable';

import {AuthService} from '../services/auth.service';
import {WindowService} from '../services/window.service';

type AuthType = 'github';
const SUPPORTED_AUTH_TYPES: AuthType[] = ['github'];

export interface OAuthWebFlowPostMessage {
  code: string;
}

/**
 * Path should match 'auth/<supported auth type>'
 * Ex. 'auth/github'
 */
export function authPathMatcher(url: UrlSegment[]): UrlMatchResult {
  const isAuthPath = url.length === 2 && url[0].path === 'auth' &&
      SUPPORTED_AUTH_TYPES.includes(url[1].path as AuthType);

  return isAuthPath ? ({consumed: url}) : null;
}

function getAuthTypeFromSegments(segments: UrlSegment[]): AuthType {
  // The auth type is just the last segment
  // Ex. <host>/auth/github, 'github' would be the type
  return segments[segments.length - 1].path as AuthType;
}


@Component({selector: 'fci-auth', template: ''})
export class AuthComponent {
  private readonly windowOpener: Window;
  private readonly window: Window;

  constructor(
      private readonly route: ActivatedRoute, private readonly router: Router,
      windowService: WindowService) {
    this.window = windowService.nativeWindow;
    this.windowOpener = this.window.opener;

    if (!this.windowOpener) {
      // we should only be here if another window opens us. re-route to home
      this.router.navigate(['/']);
    }

    this.tellParentWindowTheOAuthCode();
  }

  private tellParentWindowTheOAuthCode() {
    Observable.combineLatest(this.route.url, this.route.queryParams)
        .subscribe(([segments, queryParams]) => {
          const authType = getAuthTypeFromSegments(segments);
          switch (authType) {
            case 'github':
              const postMessage:
                  OAuthWebFlowPostMessage = {code: queryParams['code']};
              this.windowOpener.postMessage(
                  postMessage, this.window.location.origin);

              // focus back on the original window
              this.window.open('', this.windowOpener.name);
              this.window.close();
              break;
            default:
              throw new Error(`Unknown auth type ${authType}`);
          }
        });
  }
}
