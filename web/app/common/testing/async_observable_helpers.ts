/*
 * Mock async observables that return asynchronously.
 * The observable either emits once and completes or errors.
 *
 * Must call `tick()` when test with `fakeAsync()`.
 *
 * THE FOLLOWING DON'T WORK
 * Using `of().delay()` triggers TestBed errors;
 * see https://github.com/angular/angular/issues/10127 .
 *
 * Using `asap` scheduler - as in `of(value, asap)` - doesn't work either.
 *
 * Copied from Angular's
 * https://github.com/angular/angular/blob/master/aio/content/examples/testing/src/testing/async-observable-helpers.ts
 */
import {Observable} from 'rxjs';

// #docregion async-data
/**
 * Create async observable that emits-once and completes
 *  after a JS engine turn
 */
export function asyncData<T>(data: T) {
  return Observable.defer(() => Promise.resolve(data));
}
// #enddocregion async-data

// #docregion async-error
/**
 * Create async observable error that errors
 *  after a JS engine turn
 */
export function asyncError<T>(errorObject: any) {
  return Observable.defer(() => Promise.reject(errorObject));
}
// #enddocregion async-error
