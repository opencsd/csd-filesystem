import { HttpClientTestingModule } from '@angular/common/http/testing';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';

import { NgbNavModule } from '@ng-bootstrap/ng-bootstrap';

import { SharedModule } from '~/app/shared/shared.module';
import { configureTestBed, TabHelper } from '~/testing/unit-test-helper';
import { RgwUserS3Key } from '../models/rgw-user-s3-key';
import { RgwUserDetailsComponent } from './rgw-user-details.component';

describe('RgwUserDetailsComponent', () => {
  let component: RgwUserDetailsComponent;
  let fixture: ComponentFixture<RgwUserDetailsComponent>;

  configureTestBed({
    declarations: [RgwUserDetailsComponent],
    imports: [BrowserAnimationsModule, HttpClientTestingModule, SharedModule, NgbNavModule]
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(RgwUserDetailsComponent);
    component = fixture.componentInstance;
    component.selection = {};
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();

    const tabs = TabHelper.getTextContents(fixture);
    expect(tabs).toContain('Details');
    expect(tabs).not.toContain('Keys');
  });

  it('should show "Details" tab', () => {
    component.selection = { uid: 'myUsername' };
    fixture.detectChanges();

    const tabs = TabHelper.getTextContents(fixture);
    expect(tabs).toContain('Details');
    expect(tabs).not.toContain('Keys');
  });

  it('should show "Keys" tab', () => {
    const s3Key = new RgwUserS3Key();
    component.selection = { keys: [s3Key] };
    component.ngOnChanges();
    fixture.detectChanges();

    const tabs = TabHelper.getTextContents(fixture);
    expect(tabs).toContain('Details');
    expect(tabs).toContain('Keys');
  });

  it('should show correct "System" info', () => {
    component.selection = { uid: '', email: '', system: 'true', keys: [], swift_keys: [] };

    component.ngOnChanges();
    fixture.detectChanges();

    const detailsTab = fixture.debugElement.nativeElement.querySelectorAll(
      '.table.table-striped.table-bordered tr td'
    );
    expect(detailsTab[10].textContent).toEqual('System');
    expect(detailsTab[11].textContent).toEqual('Yes');

    component.selection.system = 'false';
    component.ngOnChanges();
    fixture.detectChanges();

    expect(detailsTab[11].textContent).toEqual('No');
  });

  it('should show mfa ids only if length > 0', () => {
    component.selection = {
      uid: 'dashboard',
      email: '',
      system: 'true',
      keys: [],
      swift_keys: [],
      mfa_ids: ['testMFA1', 'testMFA2']
    };

    component.ngOnChanges();
    fixture.detectChanges();

    const detailsTab = fixture.debugElement.nativeElement.querySelectorAll(
      '.table.table-striped.table-bordered tr td'
    );
    expect(detailsTab[14].textContent).toEqual('MFAs(Id)');
    expect(detailsTab[15].textContent).toEqual('testMFA1, testMFA2');
  });
});
