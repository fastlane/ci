import {BuildArtifactResponse} from './build';

export interface ConfiguredSectionsResponse {
  encryption_key: boolean;
  oauth: boolean;
  config_repo: boolean;
}

export class ConfiguredSections {
  encryptionKey: boolean;
  oAuth: boolean;
  configRepo: boolean;

  constructor(sections: ConfiguredSectionsResponse) {
    this.encryptionKey = sections.encryption_key;
    this.oAuth = sections.oauth;
    this.configRepo = sections.config_repo;
  }

  areAllSectionsConfigured(): boolean {
    return this.encryptionKey && this.oAuth && this.configRepo;
  }
}
