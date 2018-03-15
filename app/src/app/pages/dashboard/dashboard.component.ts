import {DOCUMENT} from '@angular/common';
import {Component, Inject, OnInit} from '@angular/core';

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.css']
})

export class DashboardComponent implements OnInit {
  constructor(@Inject(DOCUMENT) private document: any) {
    this.document.location.href = `${this.document.location.origin}/dashboard`
  }

  ngOnInit() {}
}
