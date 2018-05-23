import {CommonModule} from '@angular/common';
import {NgModule} from '@angular/core';
import {RouterModule} from '@angular/router';

import {ToolbarComponent} from './toolbar.component';

@NgModule({
  declarations: [ToolbarComponent],
  imports: [RouterModule, CommonModule],
  exports: [ToolbarComponent]
})
export class ToolbarModule {
}
