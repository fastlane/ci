import {Component} from '@angular/core';

/**
 * This component provides inserts for a dual panel card. The left side of the
 * panel is used for navigation and the right side displays the content. The
 * activated label and content displaying mechanism must be implemented by the
 * user.
 *
 * Import the `_master-detail-card-shared-styles` to get the class styles
 * demonstrated in the example below.
 *
 * Ex.
 *
 * <div fci-master>
 *   <div class="fci-master-section-header">Section header</div>
 *   <div class="fci-master-section-label">Section 1</div>
 *   <div class="fci-master-section-label">Section 2</div>
 * </div>
 * <div fci-detail class="fci-detail-container">
 *   ...
 * </div>
 */
@Component({
  selector: 'fci-master-detail-card',
  templateUrl: './master-detail-card.component.html',
  styleUrls: ['./master-detail-card.component.scss']
})
export class MasterDetailCardComponent {
}
