import {Component, Inject} from '@angular/core';
import {FormBuilder, FormGroup, Validators} from '@angular/forms';
import {MAT_DIALOG_DATA, MatDialogConfig, MatDialogRef} from '@angular/material';

import {Project} from '../../models/project';

export interface SettingsDialogData {
  project: Project;
}

enum MasterSection {
  GENERAL
}

const MASTER_SECTION_LABELS_MAP: Map<MasterSection, string> =
    new Map([[MasterSection.GENERAL, 'General']]);

function buildGeneralForm(fb: FormBuilder, project: Project): FormGroup {
  return fb.group({
    'name': [{value: project.name, disabled: true}, Validators.required],
    'lane': [{value: project.lane, disabled: true}, Validators.required],
  });
}

@Component({
  selector: 'fci-settings-dialog',
  templateUrl: './settings-dialog.component.html',
  styleUrls: ['./settings-dialog.component.scss']
})
export class SettingsDialogComponent {
  selectedSection = MasterSection.GENERAL;
  readonly generalForm: FormGroup;
  readonly MasterSection = MasterSection;
  readonly MASTER_SECTION_LABELS_MAP = MASTER_SECTION_LABELS_MAP;

  constructor(
      private readonly dialogRef: MatDialogRef<SettingsDialogComponent>,
      @Inject(MAT_DIALOG_DATA) dialogData: SettingsDialogData,
      fb: FormBuilder,
  ) {
    this.generalForm = buildGeneralForm(fb, dialogData.project);
  }

  closeDialog(): void {
    this.dialogRef.close();
  }

  selectSection(section: MasterSection): void {
    this.selectedSection = section;
  }

  masterSections(): MasterSection[] {
    return Array.from(this.MASTER_SECTION_LABELS_MAP.keys());
  }
}
