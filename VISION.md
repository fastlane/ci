# Vision for fastlane.ci

[Check out the statement on the main page](/README.md#statement)

## Table of Contents:
- [Goals for the initial release](#goals-for-the-initial-release)
- [Long-term goals](#long-term-goals)
  * [Notes](#notes)
- [How to contribute](https://github.com/fastlane/ci/blob/master/CONTRIBUTING.md#contributing)
  * [GitHub Project](https://github.com/fastlane/ci/blob/master/CONTRIBUTING.md#github-project)
  * [Project Milestones](https://github.com/fastlane/ci/blob/master/CONTRIBUTING.md#project-milestones)
  * [Before You Start](https://github.com/fastlane/ci/blob/master/CONTRIBUTING.md#before-you-start)

## Goals for the initial release

- **Git first**: 100% of your configuration files are stored in git, wherever you want
- **Configuration files first**: Human readable and editable config files, fully transparent
- **Open source**: Just like _fastlane_, `fastlane.ci` is open source and community driven
- **Self hosted**: You should be able to own your CI systems, and scale up as needed
- **Adapters**: Store your configuration and artifacts on services you already use, like GitHub or your own git server
- **Native fastlane integration**: Already use _fastlane_? `fastlane.ci` will work right out of the box for you
- **Mobile first, mobile only**: For now, we're focusing exclusively on building the best CI system for mobile app devs
- **Built in the open**: Together with all of you, MIT licensed
- **Visual interface**: Thanks to `fastlane.ci` you'll be able to benefit from _fastlane_ without having to use the terminal
- **Sensible defaults**: If something can be automatically figured out by `fastlane.ci`, it should be
- **Easy permissions**: Instead of manually managing an extra layer of permission, `fastlane.ci` just uses GitHub
- **Focus on the most established toolings**: git, GitHub and Xcode
- **No build steps**: `fastlane.ci` will never allow you to add "build steps", instead, all automation is done via _fastlane_

## Long-term goals

- Support common projects like React Native out of the box with zero configuration
- Manage Xcode installations for the user (using [xcode-install](https://github.com/KrauseFx/xcode-install))
- Support for distributed building for setups that require faster builds (multiple Macs)

### Notes

`mobile` refers to iOS in the beginning, and will be expanded to Android at a later stage of this project.
