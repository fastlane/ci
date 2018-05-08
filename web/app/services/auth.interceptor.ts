import {HttpErrorResponse, HttpEvent, HttpHandler, HttpInterceptor, HttpRequest} from '@angular/common/http';
import {Injectable} from '@angular/core';
import {Router} from '@angular/router';
import {Observable} from 'rxjs/Observable';
import {shareReplay} from 'rxjs/operators/shareReplay';
import {tap} from 'rxjs/operators/tap';

import {LocalStorageKeys} from '../common/constants';

/**
 * Intercepts the outgoing HTTP requests and attaches the stored JSON web token
 * to the HTTP header as an Auth Bearer. This saves us from having to attach the
 * auth token on every request me make manually.
 */
@Injectable()
export class AuthInterceptor implements HttpInterceptor {
  constructor(private readonly router: Router) {}

  intercept(req: HttpRequest<any>, next: HttpHandler):
      Observable<HttpEvent<any>> {
    let interceptedRequest: Observable<HttpEvent<any>>;
    const token = localStorage.getItem(LocalStorageKeys.AUTH_TOKEN);

    // Attach auth token to request if it exists. Otherwise, handle it normally.
    if (token) {
      const authorizedRequest = req.clone(
          {headers: req.headers.set('Authorization', `Bearer ${token}`)});

      interceptedRequest = next.handle(authorizedRequest);
    } else {
      interceptedRequest = next.handle(req);
    }

    return interceptedRequest.pipe(
        tap(null, (error: any) => {
          if (error instanceof HttpErrorResponse && error.status === 401) {
            // redirect to the login route
            this.router.navigate(['/login']);
          }
        }), shareReplay());
  }
}
