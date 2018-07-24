import {DOCUMENT} from '@angular/common';
import {ChangeDetectorRef, Component, Inject, OnInit, ViewChild} from '@angular/core';
import {AfterViewInit} from '@angular/core/src/metadata/lifecycle_hooks';
import {FormBuilder, FormGroup, Validators} from '@angular/forms';
import {MatVerticalStepper} from '@angular/material';

import {ConfiguredSections} from '../models/configured_sections';
import {DataService} from '../services/data.service';

function buildEncryptionKeyForm(fb: FormBuilder): FormGroup {
  return fb.group({
    'encryptionKey': ['', Validators.required],
  });
}

@Component({
  selector: 'fci-onboard',
  templateUrl: './onboard.component.html',
  styleUrls: ['./onboard.component.scss']
})
export class OnboardComponent implements OnInit {
  @ViewChild('stepper') stepper: MatVerticalStepper;
  readonly encryptionKeyForm: FormGroup;
  configuredSections: ConfiguredSections;
  isSettingEncryptionKey = false;

  constructor(
      @Inject(DOCUMENT) private readonly document: any,
      private readonly dataService: DataService,
      private readonly changeDetector: ChangeDetectorRef,
      fb: FormBuilder,
  ) {
    this.encryptionKeyForm = buildEncryptionKeyForm(fb);
  }

  ngOnInit(): void {
    this.dataService.getServerConfiguredSections().subscribe(
        (serverConfiguredSections) => {
          this.configuredSections = serverConfiguredSections;

          // TODO: route to dashboard if all is configured

          // Init stepper
          this.changeDetector.detectChanges();
          this.navigateToUnconfiguredSection();
        });
  }

  setEncryptionKey(): void {
    if (this.encryptionKeyForm.valid && !this.isSettingEncryptionKey) {
      this.isSettingEncryptionKey = true;
      this.dataService
          .setEncryptionKey(this.encryptionKeyForm.get('encryptionKey').value)
          .subscribe(() => {
            this.isSettingEncryptionKey = false;
            this.configuredSections.encryptionKey = true;
            // update stepper completion input
            this.changeDetector.detectChanges();
            this.navigateToUnconfiguredSection();
          });
    }
  }

  goToOldOnboarding() {
    this.document.location.href =
        `${this.document.location.origin}/onboarding_erb`;
  }

  private navigateToUnconfiguredSection(): void {
    const sectionKeys = Object.keys(this.configuredSections);
    for (let index = 0; index < sectionKeys.length; index++) {
      const configuredSection = this.configuredSections[sectionKeys[index]];
      if (configuredSection === false) {
        this.stepper.selectedIndex = index;
        break;
      }
    }
  }
}
