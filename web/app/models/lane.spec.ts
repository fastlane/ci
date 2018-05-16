import {mockLaneResponse} from '../common/test_helpers/mock_lane_data';
import {Lane} from './lane';

describe('Lane Model', () => {
  it('should convert lane response successfully', () => {
    const lane = new Lane(mockLaneResponse);

    expect(lane.name).toBe('test');
    expect(lane.platform).toBe('ios');
  });

  it('should get the full name of the lane', () => {
    const lane = new Lane(mockLaneResponse);

    expect(lane.getFullName()).toBe('ios test');
  });
});
