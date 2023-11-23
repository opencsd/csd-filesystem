import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { RouterModule, Routes } from '@angular/router';

import { NgbNavModule, NgbTooltipModule } from '@ng-bootstrap/ng-bootstrap';
import { NgxPipeFunctionModule } from 'ngx-pipe-function';

import { ActionLabels, URLVerbs } from '~/app/shared/constants/app.constants';
import { SharedModule } from '~/app/shared/shared.module';
import { PerformanceCounterModule } from '../performance-counter/performance-counter.module';
import { RgwBucketDetailsComponent } from './rgw-bucket-details/rgw-bucket-details.component';
import { RgwBucketFormComponent } from './rgw-bucket-form/rgw-bucket-form.component';
import { RgwBucketListComponent } from './rgw-bucket-list/rgw-bucket-list.component';
import { RgwDaemonDetailsComponent } from './rgw-daemon-details/rgw-daemon-details.component';
import { RgwDaemonListComponent } from './rgw-daemon-list/rgw-daemon-list.component';
import { RgwUserCapabilityModalComponent } from './rgw-user-capability-modal/rgw-user-capability-modal.component';
import { RgwUserDetailsComponent } from './rgw-user-details/rgw-user-details.component';
import { RgwUserFormComponent } from './rgw-user-form/rgw-user-form.component';
import { RgwUserListComponent } from './rgw-user-list/rgw-user-list.component';
import { RgwUserS3KeyModalComponent } from './rgw-user-s3-key-modal/rgw-user-s3-key-modal.component';
import { RgwUserSubuserModalComponent } from './rgw-user-subuser-modal/rgw-user-subuser-modal.component';
import { RgwUserSwiftKeyModalComponent } from './rgw-user-swift-key-modal/rgw-user-swift-key-modal.component';

@NgModule({
  imports: [
    CommonModule,
    SharedModule,
    FormsModule,
    ReactiveFormsModule,
    PerformanceCounterModule,
    NgbNavModule,
    RouterModule,
    NgbTooltipModule,
    NgxPipeFunctionModule
  ],
  exports: [
    RgwDaemonListComponent,
    RgwDaemonDetailsComponent,
    RgwBucketFormComponent,
    RgwBucketListComponent,
    RgwBucketDetailsComponent,
    RgwUserListComponent,
    RgwUserDetailsComponent
  ],
  declarations: [
    RgwDaemonListComponent,
    RgwDaemonDetailsComponent,
    RgwBucketFormComponent,
    RgwBucketListComponent,
    RgwBucketDetailsComponent,
    RgwUserListComponent,
    RgwUserDetailsComponent,
    RgwBucketFormComponent,
    RgwUserFormComponent,
    RgwUserSwiftKeyModalComponent,
    RgwUserS3KeyModalComponent,
    RgwUserCapabilityModalComponent,
    RgwUserSubuserModalComponent
  ]
})
export class RgwModule {}

const routes: Routes = [
  {
    path: '' // Required for a clean reload on daemon selection.
  },
  { path: 'daemon', component: RgwDaemonListComponent, data: { breadcrumbs: 'Daemons' } },
  {
    path: 'user',
    data: { breadcrumbs: 'Users' },
    children: [
      { path: '', component: RgwUserListComponent },
      {
        path: URLVerbs.CREATE,
        component: RgwUserFormComponent,
        data: { breadcrumbs: ActionLabels.CREATE }
      },
      {
        path: `${URLVerbs.EDIT}/:uid`,
        component: RgwUserFormComponent,
        data: { breadcrumbs: ActionLabels.EDIT }
      }
    ]
  },
  {
    path: 'bucket',
    data: { breadcrumbs: 'Buckets' },
    children: [
      { path: '', component: RgwBucketListComponent },
      {
        path: URLVerbs.CREATE,
        component: RgwBucketFormComponent,
        data: { breadcrumbs: ActionLabels.CREATE }
      },
      {
        path: `${URLVerbs.EDIT}/:bid`,
        component: RgwBucketFormComponent,
        data: { breadcrumbs: ActionLabels.EDIT }
      }
    ]
  }
];

@NgModule({
  imports: [RgwModule, RouterModule.forChild(routes)]
})
export class RoutedRgwModule {}
