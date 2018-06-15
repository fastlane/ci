import {Component, HostBinding} from '@angular/core';

@Component({selector: 'fci-root', templateUrl: './root.component.html'})
export class RootComponent {
  @HostBinding('class') classes = ['fci-full-height-container'];
}
