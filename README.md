<h3 align="center">
  <img src="docs/assets/fastlane_text.png" alt="fastlane Logo" width=500 />
</h3>

[![Twitter: @KrauseFx](https://img.shields.io/badge/contact-@KrauseFx-blue.svg?style=flat)](https://twitter.com/KrauseFx)
[![Twitter: @taquitos](https://img.shields.io/badge/contact-@taquitos-blue.svg?style=flat)](https://twitter.com/taquitos)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/fastlane/ci/blob/master/LICENSE)

# [WIP] fastlane.ci

Open source, self-hosted, mobile-optimized CI powered by [fastlane](https://fastlane.tools) brought to you by the _fastlane_ team.

- **Git first**: 100% of your configuration files are stored in git, wherever you want
- **Configuration files first**: Human readable and editable config files, fully transparent
- **Open source**: Just like _fastlane_, `fastlane.ci` is open source and community driven
- **Self hosted**: You should be able to own your CI systems, and scale up as needed
- **Adapters**: Store your configuration and artifacts on services you already use, like GitHub or your own git server
- **Native fastlane integration**: Already use _fastlane_? `fastlane.ci` will work right out of the box for you
- **Mobile first, mobile only**: For now, we're focusing exclusively on building the best CI system for mobile app devs
- **Built in the open**: Together with all of you, MIT licensed

## Statement

We strongly believe in making Continuous Integration systems for mobile app developers better. While CI is a solved problem for backend and frontend applications, mobile ecosystems saw almost no improvements in their workflows. Three years ago we solved the problem of mobile app deployment with _fastlane_. We want to stay true to our long-term vision of automating every single aspect of your daily development workflow. Together, with the community, we have the experience and know-how to build a world-class, easy-to-use mobile-only CI, with the added benefits of being fully self-hosted and open source.

With this project, we don't just want to make using CI easier, we want to bring [fastlane](https://fastlane.tools) to the next level. While building fastlane.ci, we'll be introducing new features like visually previewing your Fastfile, automatically clearing old TestFlight testers from your account, getting notifications when your app gets approved, and more.

[Interested? Be the first to hear about the official release](https://tinyletter.com/fastlane-tools)

<img src="docs/assets/github_pr_status.png" width="600" />

## Project Status

- This project is a very early Work In Progress (WIP) and can't be used yet
- The idea is to build and iterate with the mobile development community out in the open
- We'd love your help to shape the product, check out [CONTRIBUTING.md](CONTRIBUTING.md) for more info
- Our complete task list is available on our public [GitHub board](https://github.com/fastlane/ci/projects/1)
- We also have our current [milestones listed](https://github.com/fastlane/ci/milestones)
- We started a [poll](https://github.com/fastlane/ci/issues/93) to get a better feeling of how you'd be using `fastlane.ci`, please comment and let us know.

<a href="https://github.com/fastlane/ci/milestones">
  <img src="docs/assets/github_milestones.png" width="600" />
</a>

## Docs

- [VISION.md](VISION.md): Describes the overall vision and idea of this project, with its core principials
- [docs/SystemArchitecture.md](docs/SystemArchitecture.md): Describes the overall design architecture of `fastlane.ci`, including the controllers, services, data sources, and data objects
- [How we store builds and their artifacts](https://github.com/fastlane/ci/issues/40#issuecomment-359507244)

## System Requirements

Requires Ruby 2.3.0 or higher. macOS and Xcode are required when building iOS projects. Refer to the [fastlane documentation](https://docs.fastlane.tools/getting-started/ios/setup/#installing-fastlane) for more information.

## Development installation

```
bundle install --path vendor/bundle
```

## Local development

```
bundle exec rackup -p 8080 --env development
```

Visit [127.0.0.1:8080](http://127.0.0.1:8080/) to open the login

If you're having trouble and need to debug, you can add the following environment variables:
`FASTLANE_CI_SUPER_VERBOSE=1` and `DEBUG=1`

`FASTLANE_CI_SUPER_VERBOSE` enables extra logging which includes thread ids, and other non-essential information that could be useful during debugging.


## Run tests

```
bundle exec rspec
```

## Code style

```
bundle exec rubocop -a
```
