import {Component, Input, OnInit} from '@angular/core';
import {Params} from '@angular/router';

export interface Breadcrumb {
  hint?: string;
  label?: string;
  url?: string;
}

@Component({
  selector: 'fci-toolbar',
  templateUrl: './toolbar.component.html',
  styleUrls: ['./toolbar.component.scss']
})
export class ToolbarComponent {
  // TODO: This should be redesigned to pull the URL from the Router instead of
  // having it being manually inputted. The only input needed are the names of
  // the crumbs. The problem with doing this right now is that it doesn't make
  // sense to make these routes children of each other. So for now there is no
  // hierarchy defined anywhere which is why there's a manual input to this
  // component.
  @Input() breadcrumbs: Breadcrumb[];

  getDisplayText(breadcrumb: Breadcrumb): string {
    if (breadcrumb.label) {
      return breadcrumb.label;
    } else if (breadcrumb.hint) {
      return breadcrumb.hint;
    } else {
      return 'Loading';
    }
  }
}
