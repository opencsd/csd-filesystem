import { Component, OnDestroy, OnInit } from '@angular/core';

import { NgbModalRef } from '@ng-bootstrap/ng-bootstrap';
import { Subscription } from 'rxjs';

import { Pool } from '~/app/ceph/pool/pool';
import { RbdMirroringService } from '~/app/shared/api/rbd-mirroring.service';
import { Icons } from '~/app/shared/enum/icons.enum';
import { ViewCacheStatus } from '~/app/shared/enum/view-cache-status.enum';
import { CdTableAction } from '~/app/shared/models/cd-table-action';
import { CdTableSelection } from '~/app/shared/models/cd-table-selection';
import { Permission } from '~/app/shared/models/permissions';
import { AuthStorageService } from '~/app/shared/services/auth-storage.service';
import { ModalService } from '~/app/shared/services/modal.service';
import { BootstrapCreateModalComponent } from '../bootstrap-create-modal/bootstrap-create-modal.component';
import { BootstrapImportModalComponent } from '../bootstrap-import-modal/bootstrap-import-modal.component';
import { EditSiteNameModalComponent } from '../edit-site-name-modal/edit-site-name-modal.component';

@Component({
  selector: 'cd-mirroring',
  templateUrl: './overview.component.html',
  styleUrls: ['./overview.component.scss']
})
export class OverviewComponent implements OnInit, OnDestroy {
  permission: Permission;
  tableActions: CdTableAction[];
  selection = new CdTableSelection();
  modalRef: NgbModalRef;
  peersExist = true;
  siteName: any;
  status: ViewCacheStatus;
  private subs = new Subscription();

  constructor(
    private authStorageService: AuthStorageService,
    private rbdMirroringService: RbdMirroringService,
    private modalService: ModalService
  ) {
    this.permission = this.authStorageService.getPermissions().rbdMirroring;

    const editSiteNameAction: CdTableAction = {
      permission: 'update',
      icon: Icons.edit,
      click: () => this.editSiteNameModal(),
      name: $localize`Edit Site Name`,
      canBePrimary: () => true,
      disable: () => false
    };
    const createBootstrapAction: CdTableAction = {
      permission: 'update',
      icon: Icons.upload,
      click: () => this.createBootstrapModal(),
      name: $localize`Create Bootstrap Token`,
      disable: () => false
    };
    const importBootstrapAction: CdTableAction = {
      permission: 'update',
      icon: Icons.download,
      click: () => this.importBootstrapModal(),
      name: $localize`Import Bootstrap Token`,
      disable: () => this.peersExist
    };
    this.tableActions = [editSiteNameAction, createBootstrapAction, importBootstrapAction];
  }

  ngOnInit() {
    this.subs.add(this.rbdMirroringService.startPolling());
    this.subs.add(
      this.rbdMirroringService.subscribeSummary((data) => {
        this.status = data.content_data.status;
        this.siteName = data.site_name;

        this.peersExist = !!data.content_data.pools.find((o: Pool) => o['peer_uuids'].length > 0);
      })
    );
  }

  ngOnDestroy(): void {
    this.subs.unsubscribe();
  }

  editSiteNameModal() {
    const initialState = {
      siteName: this.siteName
    };
    this.modalRef = this.modalService.show(EditSiteNameModalComponent, initialState);
  }

  createBootstrapModal() {
    const initialState = {
      siteName: this.siteName
    };
    this.modalRef = this.modalService.show(BootstrapCreateModalComponent, initialState);
  }

  importBootstrapModal() {
    const initialState = {
      siteName: this.siteName
    };
    this.modalRef = this.modalService.show(BootstrapImportModalComponent, initialState);
  }
}
