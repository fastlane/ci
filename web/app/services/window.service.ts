import {Injectable} from '@angular/core';

@Injectable()
export class WindowService {
  get nativeWindow(): Window {
    // return the global window object
    return window;
  }

  getExternalUrl(path: string): string {
    // TODO: Get base HREF from backend on app init
    // TODO: check if path is valid once this PR is merged
    // https://github.com/angular/angular/pull/15826
    return window.location.origin + path;
  }
}
