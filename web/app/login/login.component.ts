import {Component, OnInit} from '@angular/core';
import {Router} from '@angular/router';

import {AuthService} from '../services/auth.service';

@Component({
  selector: 'fci-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.scss']
})
export class LoginComponent {
  email: string;
  password: string;

  isLoggingIn = false;
  hasError = false;

  constructor(
      private readonly authService: AuthService,
      private readonly router: Router) {}

  login(): void {
    this.isLoggingIn = true;
    this.hasError = false;

    this.authService.login({email: this.email, password: this.password})
        .subscribe(() => {
          this.isLoggingIn = false;

          // TODO: preserve user's state and return to that instead
          // Logged-in go back to landing page
          this.router.navigate(['/']);
        }, () => {
          this.isLoggingIn = false;
          this.hasError = true;
        });
  }
}
