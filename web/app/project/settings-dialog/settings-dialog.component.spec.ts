import {CommonModule} from '@angular/common';
import {DebugElement} from '@angular/core/src/debug/debug_node';
import {async, ComponentFixture, TestBed} from '@angular/core/testing';
import {ReactiveFormsModule} from '@angular/forms';
import {MAT_DIALOG_DATA, MatButtonModule, MatDialogRef, MatInputModule} from '@angular/material';
import {By} from '@angular/platform-browser';
import {BrowserAnimationsModule} from '@angular/platform-browser/animations';
import {first} from 'rxjs/operators/first';

import {MasterDetailCardModule} from '../../common/components/master-detail-card/master-detail-card.module';
import {getMockProject} from '../../common/test_helpers/mock_project_data';

import {SettingsDialogComponent} from './settings-dialog.component';

describe('SettingsDialogComponent', () => {
  let component: SettingsDialogComponent;
  let dialogRef: jasmine.SpyObj<Partial<MatDialogRef<SettingsDialogComponent>>>;
  let fixture: ComponentFixture<SettingsDialogComponent>;

  function doesElementExist(selector: string): boolean {
    return fixture.debugElement.queryAll(By.css(selector)).length > 0;
  }

  function getElement(selector: string, index: number = 0): DebugElement {
    return fixture.debugElement.queryAll(By.css(selector))[index];
  }

  beforeEach(async(() => {
    dialogRef = {close: jasmine.createSpy()};
    TestBed
        .configureTestingModule({
          declarations: [SettingsDialogComponent],
          imports: [
            CommonModule, ReactiveFormsModule, MasterDetailCardModule,
            MatInputModule, MatButtonModule, BrowserAnimationsModule
          ],
          providers: [
            {provide: MAT_DIALOG_DATA, useValue: {project: getMockProject()}},
            {provide: MatDialogRef, useValue: dialogRef}
          ]
        })
        .compileComponents();

    fixture = TestBed.createComponent(SettingsDialogComponent);
    component = fixture.componentInstance;

    fixture.detectChanges();
  }));

  describe('General Settings', () => {
    it('Should close dialog when close button is clicked', () => {
      getElement('.fci-button-container button[type="button"]')
          .nativeElement.click();
      expect(dialogRef.close).toHaveBeenCalled();
    });

    it('Should show general settings label as first label', () => {
      const firstLabel = getElement('.fci-master-section-label', 0);
      expect(firstLabel.nativeElement.innerText).toBe('General');
    });

    it('Should show General Settings content when section is clicked', () => {
      // TODO: Change this to a different Section after adding Env vards
      component.selectedSection = null;
      fixture.detectChanges();

      expect(doesElementExist('.fci-general-form')).toBe(false);
      component.selectedSection = component.MasterSection.GENERAL;
      fixture.detectChanges();

      expect(doesElementExist('.fci-general-form')).toBe(true);
    });

    // TODO: Fill these tests out once feature as complete
    it('Should submit changes when Done button is clicked', () => {});
    it('Should have Project name properly bound to form', () => {});
    it('Should have lane select properly bound to form', () => {});
  });

  describe('Environment Variables', () => {
    // TODO: Complete these tests when a second section is added
    it('Should add the selected section class when different section is clicked',
       () => {});
    it('Should show Environment Variables content when section is clicked',
       () => {});
    it('Should show Env vars label', () => {});
  });
});
