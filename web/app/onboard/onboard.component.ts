import {DOCUMENT} from '@angular/common';
import {Component, Inject} from '@angular/core';
import {FormBuilder, FormGroup, Validators} from '@angular/forms';


function buildProjectForm(fb: FormBuilder): FormGroup {
  return fb.group({
    'encryptionKey': ['', Validators.required],
  });
}

@Component({
  selector: 'fci-onboard',
  templateUrl: './onboard.component.html',
  styleUrls: ['./onboard.component.scss']
})
export class OnboardComponent {
  readonly form: FormGroup;

  constructor(
      @Inject(DOCUMENT) private readonly document: any,
      fb: FormBuilder,
  ) {
    this.form = buildProjectForm(fb);
  }

  goToOldOnboarding() {
    this.document.location.href =
        `${this.document.location.origin}/onboarding_erb`;
  }
}
