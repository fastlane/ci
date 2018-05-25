import {Component, HostBinding} from '@angular/core';

@Component({selector: 'fci-root', templateUrl: './app.component.html'})
export class AppComponent {
  @HostBinding('class') classes = ['fci-full-height-container'];
}
