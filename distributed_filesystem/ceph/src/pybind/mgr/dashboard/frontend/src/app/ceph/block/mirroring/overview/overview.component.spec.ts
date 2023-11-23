import { HttpClientTestingModule } from '@angular/common/http/testing';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { RouterTestingModule } from '@angular/router/testing';

import { NgbNavModule, NgbProgressbarModule } from '@ng-bootstrap/ng-bootstrap';
import { ToastrModule } from 'ngx-toastr';

import { SharedModule } from '~/app/shared/shared.module';
import { configureTestBed } from '~/testing/unit-test-helper';
import { DaemonListComponent } from '../daemon-list/daemon-list.component';
import { ImageListComponent } from '../image-list/image-list.component';
import { MirrorHealthColorPipe } from '../mirror-health-color.pipe';
import { PoolListComponent } from '../pool-list/pool-list.component';
import { OverviewComponent } from './overview.component';

describe('OverviewComponent', () => {
  let component: OverviewComponent;
  let fixture: ComponentFixture<OverviewComponent>;

  configureTestBed({
    declarations: [
      DaemonListComponent,
      ImageListComponent,
      MirrorHealthColorPipe,
      OverviewComponent,
      PoolListComponent
    ],
    imports: [
      BrowserAnimationsModule,
      SharedModule,
      NgbNavModule,
      NgbProgressbarModule,
      HttpClientTestingModule,
      RouterTestingModule,
      ToastrModule.forRoot()
    ]
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(OverviewComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
