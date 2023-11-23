import { Component, OnInit } from '@angular/core';
import { Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';

import _ from 'lodash';
import { forkJoin } from 'rxjs';

import { RgwBucketService } from '~/app/shared/api/rgw-bucket.service';
import { RgwSiteService } from '~/app/shared/api/rgw-site.service';
import { RgwUserService } from '~/app/shared/api/rgw-user.service';
import { ActionLabelsI18n, URLVerbs } from '~/app/shared/constants/app.constants';
import { Icons } from '~/app/shared/enum/icons.enum';
import { NotificationType } from '~/app/shared/enum/notification-type.enum';
import { CdForm } from '~/app/shared/forms/cd-form';
import { CdFormBuilder } from '~/app/shared/forms/cd-form-builder';
import { CdFormGroup } from '~/app/shared/forms/cd-form-group';
import { CdValidators } from '~/app/shared/forms/cd-validators';
import { NotificationService } from '~/app/shared/services/notification.service';
import { RgwBucketMfaDelete } from '../models/rgw-bucket-mfa-delete';
import { RgwBucketVersioning } from '../models/rgw-bucket-versioning';

@Component({
  selector: 'cd-rgw-bucket-form',
  templateUrl: './rgw-bucket-form.component.html',
  styleUrls: ['./rgw-bucket-form.component.scss']
})
export class RgwBucketFormComponent extends CdForm implements OnInit {
  bucketForm: CdFormGroup;
  editing = false;
  owners: string[] = null;
  action: string;
  resource: string;
  zonegroup: string;
  placementTargets: object[] = [];
  isVersioningAlreadyEnabled = false;
  isMfaDeleteAlreadyEnabled = false;
  icons = Icons;

  get isVersioningEnabled(): boolean {
    return this.bucketForm.getValue('versioning');
  }
  get isMfaDeleteEnabled(): boolean {
    return this.bucketForm.getValue('mfa-delete');
  }

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private formBuilder: CdFormBuilder,
    private rgwBucketService: RgwBucketService,
    private rgwSiteService: RgwSiteService,
    private rgwUserService: RgwUserService,
    private notificationService: NotificationService,
    public actionLabels: ActionLabelsI18n
  ) {
    super();
    this.editing = this.router.url.startsWith(`/rgw/bucket/${URLVerbs.EDIT}`);
    this.action = this.editing ? this.actionLabels.EDIT : this.actionLabels.CREATE;
    this.resource = $localize`bucket`;
    this.createForm();
  }

  createForm() {
    const self = this;
    const lockDaysValidator = CdValidators.custom('lockDays', () => {
      if (!self.bucketForm || !_.get(self.bucketForm.getRawValue(), 'lock_enabled')) {
        return false;
      }
      const lockDays = Number(self.bucketForm.getValue('lock_retention_period_days'));
      return !Number.isInteger(lockDays) || lockDays === 0;
    });
    this.bucketForm = this.formBuilder.group({
      id: [null],
      bid: [
        null,
        [Validators.required],
        this.editing
          ? []
          : [CdValidators.bucketName(), CdValidators.bucketExistence(false, this.rgwBucketService)]
      ],
      owner: [null, [Validators.required]],
      'placement-target': [null, this.editing ? [] : [Validators.required]],
      versioning: [null],
      'mfa-delete': [null],
      'mfa-token-serial': [''],
      'mfa-token-pin': [''],
      lock_enabled: [{ value: false, disabled: this.editing }],
      lock_mode: ['COMPLIANCE'],
      lock_retention_period_days: [0, [CdValidators.number(false), lockDaysValidator]]
    });
  }

  ngOnInit() {
    const promises = {
      owners: this.rgwUserService.enumerate()
    };

    if (!this.editing) {
      promises['getPlacementTargets'] = this.rgwSiteService.get('placement-targets');
    }

    // Process route parameters.
    this.route.params.subscribe((params: { bid: string }) => {
      if (params.hasOwnProperty('bid')) {
        const bid = decodeURIComponent(params.bid);
        promises['getBid'] = this.rgwBucketService.get(bid);
      }

      forkJoin(promises).subscribe((data: any) => {
        // Get the list of possible owners.
        this.owners = (<string[]>data.owners).sort();

        // Get placement targets:
        if (data['getPlacementTargets']) {
          const placementTargets = data['getPlacementTargets'];
          this.zonegroup = placementTargets['zonegroup'];
          _.forEach(placementTargets['placement_targets'], (placementTarget) => {
            placementTarget['description'] = `${placementTarget['name']} (${$localize`pool`}: ${
              placementTarget['data_pool']
            })`;
            this.placementTargets.push(placementTarget);
          });

          // If there is only 1 placement target, select it by default:
          if (this.placementTargets.length === 1) {
            this.bucketForm.get('placement-target').setValue(this.placementTargets[0]['name']);
          }
        }

        if (data['getBid']) {
          const bidResp = data['getBid'];
          // Get the default values (incl. the values from disabled fields).
          const defaults = _.clone(this.bucketForm.getRawValue());

          // Get the values displayed in the form. We need to do that to
          // extract those key/value pairs from the response data, otherwise
          // the Angular react framework will throw an error if there is no
          // field for a given key.
          let value: object = _.pick(bidResp, _.keys(defaults));
          value['lock_retention_period_days'] = this.rgwBucketService.getLockDays(bidResp);
          value['placement-target'] = bidResp['placement_rule'];
          value['versioning'] = bidResp['versioning'] === RgwBucketVersioning.ENABLED;
          value['mfa-delete'] = bidResp['mfa_delete'] === RgwBucketMfaDelete.ENABLED;

          // Append default values.
          value = _.merge(defaults, value);

          // Update the form.
          this.bucketForm.setValue(value);
          if (this.editing) {
            this.isVersioningAlreadyEnabled = this.isVersioningEnabled;
            this.isMfaDeleteAlreadyEnabled = this.isMfaDeleteEnabled;
            this.setMfaDeleteValidators();
            if (value['lock_enabled']) {
              this.bucketForm.controls['versioning'].disable();
            }
          }
        }

        this.loadingReady();
      });
    });
  }

  goToListView() {
    this.router.navigate(['/rgw/bucket']);
  }

  submit() {
    // Exit immediately if the form isn't dirty.
    if (this.bucketForm.pristine) {
      this.goToListView();
      return;
    }
    const values = this.bucketForm.value;
    if (this.editing) {
      // Edit
      const versioning = this.getVersioningStatus();
      const mfaDelete = this.getMfaDeleteStatus();
      this.rgwBucketService
        .update(
          values['bid'],
          values['id'],
          values['owner'],
          versioning,
          mfaDelete,
          values['mfa-token-serial'],
          values['mfa-token-pin'],
          values['lock_mode'],
          values['lock_retention_period_days']
        )
        .subscribe(
          () => {
            this.notificationService.show(
              NotificationType.success,
              $localize`Updated Object Gateway bucket '${values.bid}'.`
            );
            this.goToListView();
          },
          () => {
            // Reset the 'Submit' button.
            this.bucketForm.setErrors({ cdSubmitButton: true });
          }
        );
    } else {
      // Add
      this.rgwBucketService
        .create(
          values['bid'],
          values['owner'],
          this.zonegroup,
          values['placement-target'],
          values['lock_enabled'],
          values['lock_mode'],
          values['lock_retention_period_days']
        )
        .subscribe(
          () => {
            this.notificationService.show(
              NotificationType.success,
              $localize`Created Object Gateway bucket '${values.bid}'`
            );
            this.goToListView();
          },
          () => {
            // Reset the 'Submit' button.
            this.bucketForm.setErrors({ cdSubmitButton: true });
          }
        );
    }
  }

  areMfaCredentialsRequired() {
    return (
      this.isMfaDeleteEnabled !== this.isMfaDeleteAlreadyEnabled ||
      (this.isMfaDeleteAlreadyEnabled &&
        this.isVersioningEnabled !== this.isVersioningAlreadyEnabled)
    );
  }

  setMfaDeleteValidators() {
    const mfaTokenSerialControl = this.bucketForm.get('mfa-token-serial');
    const mfaTokenPinControl = this.bucketForm.get('mfa-token-pin');

    if (this.areMfaCredentialsRequired()) {
      mfaTokenSerialControl.setValidators(Validators.required);
      mfaTokenPinControl.setValidators(Validators.required);
    } else {
      mfaTokenSerialControl.setValidators(null);
      mfaTokenPinControl.setValidators(null);
    }

    mfaTokenSerialControl.updateValueAndValidity();
    mfaTokenPinControl.updateValueAndValidity();
  }

  getVersioningStatus() {
    return this.isVersioningEnabled ? RgwBucketVersioning.ENABLED : RgwBucketVersioning.SUSPENDED;
  }

  getMfaDeleteStatus() {
    return this.isMfaDeleteEnabled ? RgwBucketMfaDelete.ENABLED : RgwBucketMfaDelete.DISABLED;
  }
}
