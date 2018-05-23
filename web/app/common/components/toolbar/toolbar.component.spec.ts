import {DebugElement} from '@angular/core';
import {async, ComponentFixture, TestBed} from '@angular/core/testing';
import {By} from '@angular/platform-browser';

import {RouterTestingModule} from '@angular/router/testing';
import {ToolbarComponent} from './toolbar.component';

describe('ToolbarComponent', () => {
  let component: ToolbarComponent;
  let fixture: ComponentFixture<ToolbarComponent>;

  function getCrumbs(): DebugElement[] {
    return fixture.debugElement.queryAll(By.css('.fci-crumb'));
  }

  function getFirstCrumb(): HTMLElement {
    const crumbsEl = getCrumbs();
    expect(crumbsEl.length).toBe(1);

    return crumbsEl[0].query(By.css('a,span')).nativeElement;
  }

  beforeEach(() => {
    TestBed
        .configureTestingModule(
            {declarations: [ToolbarComponent], imports: [RouterTestingModule]})
        .compileComponents();

    fixture = TestBed.createComponent(ToolbarComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should breadcrumbs correctly', () => {
    component.breadcrumbs = [{label: 'parent'}, {label: 'child'}];
    fixture.detectChanges();

    const crumbsEl = getCrumbs();
    expect(crumbsEl.length).toBe(2);
    expect(crumbsEl[0].nativeElement.innerText).toContain('parent');
    expect(crumbsEl[1].nativeElement.innerText).toContain('child');
  });

  it('should have routerLink set up if there is a url on the crumb', () => {
    component.breadcrumbs = [{label: 'parent', url: 'parent/child'}];
    fixture.detectChanges();

    const firstCrumbEl = getFirstCrumb();
    expect(firstCrumbEl.hasAttribute('href')).toBe(true);
    expect(firstCrumbEl.attributes.getNamedItem('href').value)
        .toBe('/parent/child');
  });

  it('should not have routerLink set up if there is not a url on the crumb',
     () => {
       component.breadcrumbs = [{label: 'parent'}];
       fixture.detectChanges();

       const firstCrumbEl = getFirstCrumb();
       expect(firstCrumbEl.hasAttribute('href')).toBe(false);
     });

  it('should add arrow between crumbs', () => {
    component.breadcrumbs = [{label: 'parent'}, {label: 'child'}];
    fixture.detectChanges();

    const crumbsEl = getCrumbs();
    expect(crumbsEl.length).toBe(2);
    expect(crumbsEl[0].nativeElement.innerText).toBe('parent > ');
    expect(crumbsEl[1].nativeElement.innerText).toBe('child');
  });

  it('should show hint if the label is not ready yet', () => {
    component.breadcrumbs = [{hint: 'hint'}];
    fixture.detectChanges();

    const crumbEl = getFirstCrumb();
    expect(crumbEl.innerText).toBe('hint');

    component.breadcrumbs[0].label = 'parent';
    fixture.detectChanges();
    expect(crumbEl.innerText).toBe('parent');
  });
});
