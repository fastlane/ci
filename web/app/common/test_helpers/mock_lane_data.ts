import {Lane, LaneResponse} from '../../models/lane';

export const mockLaneResponse: LaneResponse = {
  name: 'test',
  platform: 'ios'
};

export const mockLanesResponse: LaneResponse[] =
    [{name: 'test', platform: 'ios'}, {name: 'beta', platform: 'android'}];

export const mockLanes: Lane[] =
    mockLanesResponse.map((response) => new Lane(response));
