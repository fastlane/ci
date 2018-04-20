import {CommonModule} from '@angular/common';
import {NgModule} from '@angular/core';

import {SharedMaterialModule} from '../../shared_material.module';

import {StatusIconComponent} from './status-icon/status-icon.component';

@NgModule({
  declarations: [StatusIconComponent],
  imports: [SharedMaterialModule, CommonModule],
  exports: [StatusIconComponent]
})

export class CommonComponentsModule {
}
