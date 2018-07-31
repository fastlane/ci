import {Component, OnInit, Input} from '@angular/core';
import {LogLine} from './log-line/log-line.component';

@Component({
  selector: 'fci-log-viewer',
  templateUrl: './log-viewer.component.html',
  styleUrls: ['./log-viewer.component.scss']
})
export class LogViewerComponent implements OnInit {
  @Input() logLines: LogLine[] = [];
  constructor() { }

  ngOnInit() {
  }

}
