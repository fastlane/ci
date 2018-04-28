import {CommonModule} from '@angular/common';
import {async, ComponentFixture, TestBed} from '@angular/core/testing';
import {FormsModule} from '@angular/forms';
import {MatButtonModule, MatDialogModule, MatIconModule, MatSelectModule} from '@angular/material';
import {MAT_DIALOG_DATA} from '@angular/material';
import {Subject} from 'rxjs/Subject';

import {Repository} from '../../models/repository';

import {AddProjectDialogComponent} from './add-project-dialog.component';

describe('AddProjectDialogComponent', () => {
  let component: AddProjectDialogComponent;
  let fixture: ComponentFixture<AddProjectDialogComponent>;
  let reposSubject: Subject<Repository[]>;
  beforeEach(async(() => {
    reposSubject = new Subject<Repository[]>();

    TestBed
        .configureTestingModule({
          declarations: [AddProjectDialogComponent],
          providers: [{
            provide: MAT_DIALOG_DATA,
            useValue: {repositories: reposSubject.asObservable()}
          }],
          imports: [
            MatDialogModule,
            MatButtonModule,
            MatSelectModule,
            MatIconModule,
            CommonModule,
            FormsModule,

          ]
        })
        .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(AddProjectDialogComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
