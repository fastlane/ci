
import {Component, OnInit} from '@angular/core';
import {FormBuilder, FormGroup, Validators} from '@angular/forms';
import {Router} from '@angular/router';

import {CiHttpErrorResponse} from '../common/types';
import {AuthService} from '../services/auth.service';
import {DataService} from '../services/data.service';

function buildSignupForm(fb: FormBuilder): FormGroup {
  return fb.group({
    token: ['', Validators.required],
    password: ['', Validators.required],
  });
}

@Component({
  selector: 'fci-login',
  templateUrl: './signup.component.html',
  styleUrls: ['./signup.component.scss']
})
export class SignupComponent implements OnInit {
  email = '';
  error: string;
  readonly form: FormGroup;

  constructor(
      private readonly authService: AuthService,
      private readonly dataService: DataService,
      private readonly router: Router,
      fb: FormBuilder,
  ) {
    this.form = buildSignupForm(fb);
  }

  ngOnInit() {
    if (this.authService.isLoggedIn()) {
      this.router.navigate(['/']);
    }

    this.form.get('token').valueChanges.subscribe((newToken) => {
      this.getUserEmail(newToken);
    });
  }

  private getUserEmail(token: string) {
    delete this.error;

    this.dataService.getUserDetails(token).subscribe(
        (userDetails) => {
          this.email = userDetails.github.email;
        },
        (response: CiHttpErrorResponse) => {
          this.error = response.error.message;
        });
  }
}
