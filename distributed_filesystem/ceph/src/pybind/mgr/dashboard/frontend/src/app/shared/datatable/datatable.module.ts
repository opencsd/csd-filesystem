import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';

import { NgbDropdownModule, NgbTooltipModule } from '@ng-bootstrap/ng-bootstrap';
import { NgxDatatableModule } from '@swimlane/ngx-datatable';
import { NgxPipeFunctionModule } from 'ngx-pipe-function';

import { ComponentsModule } from '../components/components.module';
import { PipesModule } from '../pipes/pipes.module';
import { TableActionsComponent } from './table-actions/table-actions.component';
import { TableKeyValueComponent } from './table-key-value/table-key-value.component';
import { TableComponent } from './table/table.component';

@NgModule({
  imports: [
    CommonModule,
    NgxDatatableModule,
    NgxPipeFunctionModule,
    FormsModule,
    NgbDropdownModule,
    NgbTooltipModule,
    PipesModule,
    ComponentsModule,
    RouterModule
  ],
  declarations: [TableComponent, TableKeyValueComponent, TableActionsComponent],
  exports: [TableComponent, NgxDatatableModule, TableKeyValueComponent, TableActionsComponent]
})
export class DataTableModule {}
