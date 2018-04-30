import {HttpEvent, HttpHandler, HttpInterceptor, HttpRequest} from '@angular/common/http';
import {Injectable} from '@angular/core';
import {Observable} from 'rxjs/Observable';
import {LocalStorageKeys} from '../common/constants';

/**
 * Intercepts the outgoing HTTP requests and attaches the stored JSON web token
 * to the HTTP header as an Auth Bearer. This saves us from having to attach the
 * auth token on every request me make manually.
 */
@Injectable()
export class AuthInterceptor implements HttpInterceptor {
  intercept(req: HttpRequest<any>, next: HttpHandler):
      Observable<HttpEvent<any>> {
    const token = localStorage.getItem(LocalStorageKeys.AUTH_TOKEN);

    // Attach auth token to request if it exists. Otherwise, handle it normally.
    if (token) {
      const authorizedRequest = req.clone(
          {headers: req.headers.set('Authorization', `Bearer ${token}`)});

      return next.handle(authorizedRequest);
    } else {
      return next.handle(req);
    }
  }
}
