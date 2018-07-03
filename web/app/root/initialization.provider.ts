import 'rxjs/add/operator/map';

import {Injectable, Injector} from '@angular/core';
import {Router} from '@angular/router';

import {DataService} from '../services/data.service';

@Injectable()
export class InitializationProvider {
  constructor(
      private injector: Injector, private readonly dataService: DataService) {}

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
            this.router.navigate(['onboard']);
          }
        })
        .toPromise();
  }

  /**
   * This will return the Router dependency. It is required to inject this
   * separately because the Router depends on Http and Http depends on the
   * router. This creates a cyclical dependency when initializing the root
   * module. More information can be found here:
   * https://stackoverflow.com/questions/39767019/app-initializer-raises-cannot-instantiate-cyclic-dependency-applicationref-w
   */
  private get router(): Router {
    return this.injector.get(Router);
  }
}
