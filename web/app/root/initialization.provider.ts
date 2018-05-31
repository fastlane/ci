import {DOCUMENT} from '@angular/common';
import {Inject, Injectable} from '@angular/core';
import {Subscription} from 'rxjs/Subscription';

import {DataService} from '../services/data.service';

@Injectable()
export class InitializationProvider {
  constructor(
      @Inject(DOCUMENT) private document: any,
      private readonly dataService: DataService) {}

  initialize(): Subscription {
    return this.dataService.isServerConfigured().subscribe((isConfigured) => {
      if (!isConfigured) {
        this.document.location.href =
            `${this.document.location.origin}/onboarding_erb`;
      }
    });
  }
}
