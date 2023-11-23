import { Injectable } from '@angular/core';
import { AbstractControlOptions, FormBuilder } from '@angular/forms';

import { CdFormGroup } from './cd-form-group';

/**
 * CdFormBuilder extends FormBuilder to create an CdFormGroup based form.
 */
@Injectable({
  providedIn: 'root'
})
export class CdFormBuilder extends FormBuilder {
  group(
    controlsConfig: { [key: string]: any },
    extra: AbstractControlOptions | null = null
  ): CdFormGroup {
    const form = super.group(controlsConfig, extra);
    return new CdFormGroup(form.controls, form.validator, form.asyncValidator);
  }
}
