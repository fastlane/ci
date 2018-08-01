import {APP_BASE_HREF, Location, LocationStrategy, PathLocationStrategy} from '@angular/common';
import {Component, EventEmitter, Inject, Input, OnInit, Output} from '@angular/core';

import {AuthService} from '../../../services/auth.service';
import {GitHubScope} from '../../types';

@Component({
  selector: 'fci-github-login-button',
  templateUrl: './github-login-button.component.html',
  styleUrls: ['./github-login-button.component.scss'],
  providers:
      [Location, {provide: LocationStrategy, useClass: PathLocationStrategy}]
})
export class GithubLoginButtonComponent {
  @Input() scopes?: GitHubScope[];
  @Output() loggedIn: EventEmitter<void> = new EventEmitter<void>();
  isLoggingIn = false;

  constructor(private readonly authService: AuthService) {}

  login() {
    this.isLoggingIn = true;
    this.authService.authorize(this.scopes).subscribe(() => {
      this.isLoggingIn = false;
      this.loggedIn.emit();
    });
  }
}
