import {ConfiguredSections, ConfiguredSectionsResponse} from './configured_sections';

function getMockConfiguredSectionsResponse(): ConfiguredSectionsResponse {
  return {encryption_key: false, oauth: false, config_repo: false};
}

describe('ConfiguredSections Model', () => {
  it('should convert response successfully', () => {
    const configuredSections = new ConfiguredSections(
        {encryption_key: true, oauth: false, config_repo: true});

    expect(configuredSections.encryptionKey).toBe(true);
    expect(configuredSections.oAuth).toBe(false);
    expect(configuredSections.configRepo).toBe(true);
  });

  describe('#areAllSectionsConfigured', () => {
    it('should be true if all sections are marked configured', () => {
      const configuredSections = new ConfiguredSections(
          {encryption_key: true, oauth: true, config_repo: true});

      expect(configuredSections.areAllSectionsConfigured()).toBe(true);
    });

    it('should be false if any section is marked unconfigured', () => {
      let configuredSections = new ConfiguredSections(
          {encryption_key: true, oauth: true, config_repo: false});

      expect(configuredSections.areAllSectionsConfigured()).toBe(false);

      configuredSections = new ConfiguredSections(
          {encryption_key: true, oauth: false, config_repo: true});

      expect(configuredSections.areAllSectionsConfigured()).toBe(false);

      configuredSections = new ConfiguredSections(
          {encryption_key: false, oauth: true, config_repo: true});

      expect(configuredSections.areAllSectionsConfigured()).toBe(false);
    });
  });
});
