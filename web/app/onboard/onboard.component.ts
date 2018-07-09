import {DOCUMENT} from '@angular/common';
import {Component, Inject} from '@angular/core';
import {FormBuilder, FormGroup, Validators} from '@angular/forms';

import {GITHUB_API_TOKEN_LENGTH} from '../common/constants';
import {DataService} from '../services/data.service';


function buildProjectForm(fb: FormBuilder): FormGroup {
  return fb.group({
    'encryptionKey': ['', Validators.required],
    'botToken': ['', Validators.required],
    'botPassword': ['', Validators.required],
    'configRepo': ['', Validators.required],
  });
}

@Component({
  selector: 'fci-onboard',
  templateUrl: './onboard.component.html',
  styleUrls: ['./onboard.component.scss']
})
export class OnboardComponent {
  readonly form: FormGroup;
  botEmail: string;
  isFetchingBotEmail = false;

  constructor(
      @Inject(DOCUMENT) private readonly document: any,
      private readonly dataService: DataService,
      fb: FormBuilder,
  ) {
    this.form = buildProjectForm(fb);

    this.form.get('botToken').valueChanges.subscribe((token) => {
      delete this.botEmail;
      this.form.get('botPassword').reset();

      if (token.length === GITHUB_API_TOKEN_LENGTH) {
        this.isFetchingBotEmail = true;

        this.dataService.getUserDetails(token).subscribe((details) => {
          this.botEmail = details.github.email;
          this.isFetchingBotEmail = false;
        });
      }
    });
  }

  submitOnboarding(): void {
    if (this.form.valid) {
      console.log('Onboarding is being submitted');
    }
  }

  goToOldOnboarding() {
    this.document.location.href =
        `${this.document.location.origin}/onboarding_erb`;
  }
}
