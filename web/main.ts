import {enableProdMode} from '@angular/core';
import {platformBrowserDynamic} from '@angular/platform-browser-dynamic';

import {RootModule} from './app/root/root.module';
import {environment} from './environments/environment';

if (environment.production) {
  enableProdMode();
}

platformBrowserDynamic()
    .bootstrapModule(RootModule)
    .catch(err => console.log(err));
