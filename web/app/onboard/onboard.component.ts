import {DOCUMENT} from '@angular/common';
import {Component, Inject} from '@angular/core';

@Component({
  selector: 'fci-onboard',
  templateUrl: './onboard.component.html',
  styleUrls: ['./onboard.component.scss']
})

export class OnboardComponent {
  constructor(@Inject(DOCUMENT) private readonly document: any) {}

  goToOldOnboarding() {
    this.document.location.href =
        `${this.document.location.origin}/onboarding_erb`;
  }
}
