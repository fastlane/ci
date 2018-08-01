import {Location} from '@angular/common';
import {SpyLocation} from '@angular/common/testing';
import {inject, TestBed} from '@angular/core/testing';

import {WindowService} from './window.service';

describe('WindowService', () => {
  let windowService: WindowService;
  beforeEach(() => {
    TestBed.configureTestingModule({providers: [WindowService]});

    windowService = TestBed.get(WindowService);
  });

  it('#nativeWindow should be the global window', () => {
    expect(windowService.nativeWindow).toBe(window);
  });

  it('#getExternalUrl should give correct url', () => {
    const expectedUrl = `${window.location.origin}/auth/github`;
    expect(windowService.getExternalUrl('/auth/github')).toBe(expectedUrl);
  });
});
