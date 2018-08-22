# Xcode management

## Background

Xcode doesn't support proper versioning like other development environments do. The goal with `fastlane.ci` is to make it easy as possible for the user to upgrade their CI system to run multiple versions of Xcode in parallel depending on the branch. This allows development team to work on a `swift-x` migration branch to test Xcode-`X` features without having to break the build for the remaining branches.

## Limitations

- The Xcode build system doesn't allow specifying a version number using a file or using a CLI parameter
- There is no offical CLI or API to download and install Xcode
- There is no unified way in the iOS community yet to specify the Xcode version to use
- Xcode requires root permission to install the `Device Components` on the first launch of a new version. This step is required and can't be skipped

## Opportunity

- Managing Xcode installations is one of the top pain points for all generic CI systems. Mobile-optimzied CI systems can significantly help the user by automating the management of Xcode installations
- There is not a single self-hosted CI system out there, that automatically and easily manages Xcode installations for the user
- Introduce a new convention for the whole iOS community to specify a version of Xcode to use for a given project using a generic text-based file (e.g. `.xcode-version` containing `8.3`). This way it allows `fastlane.ci` users to specify their Xcode version, while also introducing a new generic way for other systems to integrate with it without having to use Ruby or _fastlane_

## Solution

[xcode-install](https://github.com/krausefx/xcode-install) is an open source tool maintained by @KrauseFx that allows the user to install new versions of Xcode using the command line.

As part of this project, we also created the concept of `.xcode-version` files, check out [xcode-version.md](./xcode-version.md) for a full documentation on the file format.
