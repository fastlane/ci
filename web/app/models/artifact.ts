import {BuildArtifactResponse} from './build';

export class Artifact {
  readonly id: string;
  readonly name: string;

  constructor(artifact: BuildArtifactResponse) {
    this.id = artifact.id;
    this.name = artifact.type;
  }
}
