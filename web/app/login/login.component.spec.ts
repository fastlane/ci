import {async, ComponentFixture, TestBed} from '@angular/core/testing';
import {MatButtonModule} from '@angular/material';

import {LoginComponent} from './login.component';

describe('LoginComponent', () => {
  let component: LoginComponent;
  let fixture: ComponentFixture<LoginComponent>;

  beforeEach(async(() => {
    TestBed
        .configureTestingModule(
            {declarations: [LoginComponent], imports: [MatButtonModule]})
        .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(LoginComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
