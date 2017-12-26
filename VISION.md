# Vision for fastlane.ci

## Until the first public release:

- Open Source and completely self-hosted
- Mobile first, mobile only
- Support only the most established tools mobile developers use, this includes:
  - GitHub and git
  - Xcode
- Store 100% of all CI configuration in git
- If a developer already uses [fastlane](https://fastlane.tools), they can use `fastlane.ci` out of the box by only selecting the lane to run
- Sensible defaults
- Use of the GitHub permission system to avoid having YetAnotherAccount and permission system to maintain

## Long term goals

- Support common projects like React Native out of the box with zero configuration
- Manage Xcode installations for the user
- Support for distributed building for setups that require faster builds

### Notes

`mobile` refers to iOS in the beginning, and will be expanded to Android at a later stage of this project.
