import {Component, OnInit} from '@angular/core';

@Component({
  selector: 'fci-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.scss']
})
export class LoginComponent {
  username: string;
  password: string;
  constructor() {}

  login(): void {
    // TODO: Auth Service login
  }
}
