# Connecting a new artifact provider #

`fastlane.ci` supports a flexible system to allow any kind of store options, so that developers can own their data.
For more information on how it works, check out [docs/ArtifactsAndBuilds.md](/docs/ArtifactsAndBuilds.md)

For information on how to access artifacts, check out [access_build_artifacts.md](./access_build_artifacts.md).

### Assumptions ###
- fastlane.ci already setup
- user logged in

### Results ###
The developer added a new artifact provider, which can then be used by a given project.

### Steps ###
1. User goes to opens `fastlane.ci` settings and selects `Manage artifact providers`
1. User can edit existing artifact providers
	1. Edit the name, update API tokens, etc.
1. User can click on `Add new artifact provider`
	1. Get a list of available artifact providers (Google Cloud storage, local file storage)
	1. User chooses a name for the provider (e.g. `Google Cloud build artifacts fastlane team` or `Screenshot tests`)
	1. Depending on what the user selected, the specific onboarding wizard is launched, asking for the needed information (e.g. API keys, oauth flow, etc.)
	1. Once the onboarding was successful, `fastlane.ci` offers to use the new artifact storage on what of the available projects (if any)

### Error states ###
[WIP]
