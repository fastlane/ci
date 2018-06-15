import {DOCUMENT} from '@angular/common';
import {Inject, Injectable} from '@angular/core';
import {Observable} from 'rxjs/Observable';
import {Observer} from 'rxjs/Observer';
import {Subject} from 'rxjs/Subject';

export interface BuildLogMessageEvent extends MessageEvent {
  data: string;
}

@Injectable()
export class BuildLogWebsocketService {
  private readonly API_ROOT: string;

  constructor(@Inject(DOCUMENT) document: Document) {
    this.API_ROOT = `ws://${document.location.host}/data`;
  }

  connect(projectId: string, buildNumber: number):
      Observable<BuildLogMessageEvent> {
    const socket = this.createSocket(projectId, buildNumber);
    const observable =
        Observable.create((observer: Observer<BuildLogMessageEvent>) => {
          socket.onmessage = observer.next.bind(observer);
          socket.onerror = observer.error.bind(observer);
          socket.onclose = observer.complete.bind(observer);
          return socket.close.bind(socket);
        });

    return observable;
  }

  /** Public for testing */
  createSocket(projectId: string, buildNumber: number): WebSocket {
    return new WebSocket(this.createSocketUrl(projectId, buildNumber));
  }

  private createSocketUrl(projectId: string, buildNumber: number) {
    return `${this.API_ROOT}/projects/${projectId}/builds/${
        buildNumber}/log.ws`;
  }
}
