import {
  ComponentFactoryResolver,
  Directive,
  Input,
  TemplateRef,
  ViewContainerRef
} from '@angular/core';

import { AlertPanelComponent } from '../components/alert-panel/alert-panel.component';
import { LoadingPanelComponent } from '../components/loading-panel/loading-panel.component';
import { LoadingStatus } from '../forms/cd-form';

@Directive({
  selector: '[cdFormLoading]'
})
export class FormLoadingDirective {
  constructor(
    private templateRef: TemplateRef<any>,
    private viewContainer: ViewContainerRef,
    private componentFactoryResolver: ComponentFactoryResolver
  ) {}

  @Input('cdFormLoading') set cdFormLoading(condition: LoadingStatus) {
    let factory: any;
    let content: any;

    this.viewContainer.clear();

    switch (condition) {
      case LoadingStatus.Loading:
        factory = this.componentFactoryResolver.resolveComponentFactory(LoadingPanelComponent);
        content = this.resolveNgContent($localize`Loading form data...`);
        this.viewContainer.createComponent(factory, null, null, content);
        break;
      case LoadingStatus.Ready:
        this.viewContainer.createEmbeddedView(this.templateRef);
        break;
      case LoadingStatus.Error:
        factory = this.componentFactoryResolver.resolveComponentFactory(AlertPanelComponent);
        content = this.resolveNgContent($localize`Form data could not be loaded.`);
        const componentRef = this.viewContainer.createComponent(factory, null, null, content);
        (<AlertPanelComponent>componentRef.instance).type = 'error';
        break;
    }
  }

  resolveNgContent(content: string) {
    const element = document.createTextNode(content);
    return [[element]];
  }
}
