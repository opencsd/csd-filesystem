import { Component, OnInit } from '@angular/core';

import { NgbActiveModal } from '@ng-bootstrap/ng-bootstrap';
import moment from 'moment';

import { RbdService } from '~/app/shared/api/rbd.service';
import { ActionLabelsI18n } from '~/app/shared/constants/app.constants';
import { CdFormBuilder } from '~/app/shared/forms/cd-form-builder';
import { CdFormGroup } from '~/app/shared/forms/cd-form-group';
import { CdValidators } from '~/app/shared/forms/cd-validators';
import { ExecutingTask } from '~/app/shared/models/executing-task';
import { FinishedTask } from '~/app/shared/models/finished-task';
import { ImageSpec } from '~/app/shared/models/image-spec';
import { TaskWrapperService } from '~/app/shared/services/task-wrapper.service';

@Component({
  selector: 'cd-rbd-trash-move-modal',
  templateUrl: './rbd-trash-move-modal.component.html',
  styleUrls: ['./rbd-trash-move-modal.component.scss']
})
export class RbdTrashMoveModalComponent implements OnInit {
  // initial state
  poolName: string;
  namespace: string;
  imageName: string;
  hasSnapshots: boolean;

  imageSpec: ImageSpec;
  imageSpecStr: string;
  executingTasks: ExecutingTask[];

  moveForm: CdFormGroup;
  pattern: string;

  constructor(
    private rbdService: RbdService,
    public activeModal: NgbActiveModal,
    public actionLabels: ActionLabelsI18n,
    private fb: CdFormBuilder,
    private taskWrapper: TaskWrapperService
  ) {
    this.createForm();
  }

  createForm() {
    this.moveForm = this.fb.group({
      expiresAt: [
        '',
        [
          CdValidators.custom('format', (expiresAt: string) => {
            const result = expiresAt === '' || moment(expiresAt, 'YYYY-MM-DD HH:mm:ss').isValid();
            return !result;
          }),
          CdValidators.custom('expired', (expiresAt: string) => {
            const result = moment().isAfter(expiresAt);
            return result;
          })
        ]
      ]
    });
  }

  ngOnInit() {
    this.imageSpec = new ImageSpec(this.poolName, this.namespace, this.imageName);
    this.imageSpecStr = this.imageSpec.toString();
    this.pattern = `${this.poolName}/${this.imageName}`;
  }

  moveImage() {
    let delay = 0;
    const expiresAt = this.moveForm.getValue('expiresAt');

    if (expiresAt) {
      delay = moment(expiresAt, 'YYYY-MM-DD HH:mm:ss').diff(moment(), 'seconds', true);
    }

    if (delay < 0) {
      delay = 0;
    }

    this.taskWrapper
      .wrapTaskAroundCall({
        task: new FinishedTask('rbd/trash/move', {
          image_spec: this.imageSpecStr
        }),
        call: this.rbdService.moveTrash(this.imageSpec, delay)
      })
      .subscribe({
        complete: () => {
          this.activeModal.close();
        }
      });
  }
}
