import { DOCUMENT } from '@angular/common';
import { Component, AfterViewInit, ViewChild, ElementRef, Input, Inject, ViewEncapsulation } from '@angular/core';

const ANSI_PATTERN = /\u001b\[([0-9;]+)?m/;
const ANSI_RESET_CODE = '0';

type AnsiCode = string;
type AnsiTuple = [AnsiCode, string];

export interface LogLine {
  timestamp: number;
  message: string;
  level: string;
  status: number;
}

@Component({
  selector: 'fci-log-line',
  templateUrl: './log-line.component.html',
  styleUrls: ['./log-line.component.scss'],
  encapsulation: ViewEncapsulation.None
})

export class LogLineComponent implements AfterViewInit {
  @Input() log: LogLine;
  @ViewChild('logLine', { read: ElementRef }) logLineEl: ElementRef;

  constructor(@Inject(DOCUMENT) private readonly document: any) {}

  ngAfterViewInit() {
    const parentEl = this.logLineEl.nativeElement;
    let currentSpanEl = parentEl;
    const stack = this.tokenize(this.log.message);

    for (const tuple of stack) {
      const [code, text] = tuple;
      if (code === ANSI_RESET_CODE) {
        parentEl.innerHTML += text;
        currentSpanEl = parentEl;
      } else {
        currentSpanEl = this.injectSpan(currentSpanEl, text, code);
      }
    }
  }

  /**
   * tokenization works by splitting the string by a regex that has a capture group
   * this will return an flat array of tuples (string, capture)
   * this method will split and group the result into an array of tuples [ansi code, text]
   * NOTE: that the capture comes after the string, so we transpose them.
   **/
  private tokenize(ansiText: string): AnsiTuple[] {
    const tuples = ansiText.split(ANSI_PATTERN);

    // if the text starts with a match capture (and thus returning empty string as [0]),
    // use that captured ansi code as the beginning style
    if (tuples[0] === '') {
      tuples.shift();
    } else {
      // otherwise, we must assume we are starting each line as the default '0'
      tuples.unshift(ANSI_RESET_CODE);
    }

    const stack: AnsiTuple[] = [];

    for (let i = 0; i < tuples.length; i += 2) {
      const code = tuples[i];
      const text = tuples[i + 1];
      stack.push([code, text]);
    }
    return stack;
  }

  private injectSpan(parent: HTMLElement, text: string, ansiCode: AnsiCode): HTMLSpanElement {
    const span = this.document.createElement('span');
    const classNames = ansiCode.split(';').map(c => `fci-ansi-${c}`).join(' ');
    span.className = classNames;
    span.innerText = text;
    parent.appendChild(span);

    return span;
  }
}
