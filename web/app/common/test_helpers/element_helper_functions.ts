import {DebugElement} from '@angular/core';
import {By} from '@angular/platform-browser';

function doesElementExist(context: DebugElement, selector: string): boolean {
  return context.queryAll(By.css(selector)).length > 0;
}

export function getAllElements(
    context: DebugElement, selector: string): DebugElement[] {
  const els = context.queryAll(By.css(selector));
  expect(els.length)
      .toBeGreaterThan(0, `No Elements were found\nSelector: '${selector}'`);

  return els;
}

export function getElement(
    context: DebugElement, selector: string, index: number = 0): DebugElement {
  const el = getAllElements(context, selector)[index];
  expect(el).toBeDefined(`Element is undefined\nSelector: '${selector}'`);

  return el;
}

export function getElementText(
    context: DebugElement, selector?: string, index: number = 0): string {
  const el =
      (selector ? getElement(context, selector, index) : context).nativeElement;

  return (el.innerText || el.textContent || '').trim();
}

export function expectElementToExist(context: DebugElement, selector: string) {
  return expect(doesElementExist(context, selector))
      .toBe(
          true,
          `An element was expected to exist, but was not found\nSelector: '${
              selector}'`);
}

export function expectElementNotToExist(
    context: DebugElement, selector: string) {
  return expect(doesElementExist(context, selector))
      .toBe(
          false,
          `An element was expected NOT to exist, but was found\nSelector: '${
              selector}'`);
}
