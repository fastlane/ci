import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import { LogLineComponent, LogLine } from './log-line.component';
import { Component, DebugElement } from '@angular/core';
import { getElement, getElementText } from '../../../test_helpers/element_helper_functions';

describe('LogLineComponent', () => {
  let component: LogLineComponent;
  let fixture: ComponentFixture<LogLineComponent>;
  let fixtureEl: DebugElement;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [LogLineComponent, LogLineComponent]
    }).compileComponents();

    fixture = TestBed.createComponent(LogLineComponent);
    fixtureEl = fixture.debugElement;
    component = fixture.componentInstance;
    component.log = {
      message: '[16:12:08]: \u001b[33m▸\u001b[0m \u001b[39;1mCompiling\u001b[0m Category.swift\n',
      level: 'DEBUG',
      status: 0,
      timestamp: 1531944769
    };

    fixture.detectChanges(); // onInit
  }));

  it('should create the correct span dom tree of ansi codes', () => {
    const parentEl = getElement(fixtureEl, '.fci-log-line');

    expect(parentEl.nativeElement.innerHTML).toBe(
      '[16:12:08]: <span class="fci-ansi-33">▸</span> ' +
      '<span class="fci-ansi-39 fci-ansi-1">Compiling</span>' +
      ' Category.swift\n');
  });
});
