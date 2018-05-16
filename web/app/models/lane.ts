export interface LaneResponse {
  name: string;
  platform: string;
}


export class Lane {
  readonly name: string;
  readonly platform: string;

  constructor(lane: LaneResponse) {
    this.name = lane.name;
    this.platform = lane.platform;
  }

  getFullName(): string {
    return `${this.platform} ${this.name}`;
  }
}
