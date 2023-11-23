import {
  HttpErrorResponse,
  HttpEvent,
  HttpHandler,
  HttpInterceptor,
  HttpRequest
} from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Router } from '@angular/router';

import _ from 'lodash';
import { Observable, throwError as observableThrowError } from 'rxjs';
import { catchError } from 'rxjs/operators';

import { CdHelperClass } from '~/app/shared/classes/cd-helper.class';
import { NotificationType } from '../enum/notification-type.enum';
import { CdNotificationConfig } from '../models/cd-notification';
import { FinishedTask } from '../models/finished-task';
import { AuthStorageService } from './auth-storage.service';
import { NotificationService } from './notification.service';

export class CdHttpErrorResponse extends HttpErrorResponse {
  preventDefault: Function;
  ignoreStatusCode: Function;
}

@Injectable({
  providedIn: 'root'
})
export class ApiInterceptorService implements HttpInterceptor {
  constructor(
    private router: Router,
    private authStorageService: AuthStorageService,
    public notificationService: NotificationService
  ) {}

  intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    const acceptHeader = request.headers.get('Accept');
    let reqWithVersion: HttpRequest<any>;
    if (acceptHeader && acceptHeader.startsWith('application/vnd.ceph.api.v')) {
      reqWithVersion = request.clone();
    } else {
      reqWithVersion = request.clone({
        setHeaders: {
          Accept: CdHelperClass.cdVersionHeader('1', '0')
        }
      });
    }
    return next.handle(reqWithVersion).pipe(
      catchError((resp: CdHttpErrorResponse) => {
        if (resp instanceof HttpErrorResponse) {
          let timeoutId: number;
          switch (resp.status) {
            case 400:
              const finishedTask = new FinishedTask();

              const task = resp.error.task;
              if (_.isPlainObject(task)) {
                task.metadata.component = task.metadata.component || resp.error.component;

                finishedTask.name = task.name;
                finishedTask.metadata = task.metadata;
              } else {
                finishedTask.metadata = resp.error;
              }

              finishedTask.success = false;
              finishedTask.exception = resp.error;
              timeoutId = this.notificationService.notifyTask(finishedTask);
              break;
            case 401:
              this.authStorageService.remove();
              this.router.navigate(['/login']);
              break;
            case 403:
              this.router.navigate(['error'], {
                state: {
                  message: $localize`Sorry, you don’t have permission to view this page or resource.`,
                  header: $localize`Access Denied`,
                  icon: 'fa fa-lock',
                  source: 'forbidden'
                }
              });
              break;
            default:
              timeoutId = this.prepareNotification(resp);
          }

          /**
           * Decorated preventDefault method (in case error previously had
           * preventDefault method defined). If called, it will prevent a
           * notification to be shown.
           */
          resp.preventDefault = () => {
            this.notificationService.cancel(timeoutId);
          };

          /**
           * If called, it will prevent a notification for the specific status code.
           * @param {number} status The status code to be ignored.
           */
          resp.ignoreStatusCode = function (status: number) {
            if (this.status === status) {
              this.preventDefault();
            }
          };
        }
        // Return the error to the method that called it.
        return observableThrowError(resp);
      })
    );
  }

  private prepareNotification(resp: any): number {
    return this.notificationService.show(() => {
      let message = '';
      if (_.isPlainObject(resp.error) && _.isString(resp.error.detail)) {
        message = resp.error.detail; // Error was triggered by the backend.
      } else if (_.isString(resp.error)) {
        message = resp.error;
      } else if (_.isString(resp.message)) {
        message = resp.message;
      }
      return new CdNotificationConfig(
        NotificationType.error,
        `${resp.status} - ${resp.statusText}`,
        message,
        undefined,
        resp['application']
      );
    });
  }
}
