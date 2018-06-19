import 'rxjs/add/operator/map';

import {DOCUMENT} from '@angular/common';
import {Inject, Injectable} from '@angular/core';

import {DataService} from '../services/data.service';

@Injectable()
export class InitializationProvider {
  constructor(
      @Inject(DOCUMENT) private document: any,
      private readonly dataService: DataService) {}

  /**
   * Load initial data and reroute to onboarding if the server is not
   * configured.
   *
   * @returns a promise. This is needed to have the app init wait on this call.
   */
  initialize(): Promise<void> {
    return this.dataService.isServerConfigured()
        .map((isConfigured) => {
          if (!isConfigured) {
            this.document.location.href =
                `${this.document.location.origin}/onboarding_erb`;
          }
        })
        .toPromise();
  }
}
