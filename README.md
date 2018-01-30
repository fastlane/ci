<h3 align="center">
  <img src="docs/assets/fastlane_text.png" alt="fastlane Logo" width=500 />
</h3>

# [WIP] fastlane.ci

Open source, self hosted, mobile optimized CI powered by [fastlane](https://fastlane.tools) from the same team that built _fastlane_.

- **Git first**: 100% of the configuration files are stored in git, on a server of your choice
- **Configuration files first**: Human readable and editable config files, fully transparent
- **Open source**: Just like _fastlane_, open source and community driven
- **Self hosted**: You should be able to own your CI systems, and scale up as needed
- **Adapters**: Integrate with services you already use, store artifacts where you want them
- **Native fastlane integration**: You already use _fastlane_? `fastlane.ci` will work out of the box for you
- **Mobile first, mobile only**: For now, we focus exclusively on building the best CI system for mobile app devs
- **Built in the open**: Together with all of you, MIT licensed

For more details on the vision of the project, check out [VISION.md](VISION.md)

## Statement

We strongly believe in making Continuous Integration systems for mobile app developers better. While CI is a solved problem for back-end and front-end applications, the mobile ecosystem saw almost no improvements in their workflow. With _fastlane_ we successfully solved the problem of mobile app deployment three years ago, with the long term vision to automate every single aspect of your daily development workflow. We have the experience, and the know-how to build a world-class mobile-only CI, fully self-hosted, open source and extremely easy to use. 

With this project, we don't only making using CI much easier, but it will allow us to put [fastlane](https://fastlane.tools) to the next level also. Things like previewing your Fastfile visually, automatically clearing old TestFlight testers from your account and getting notifications when your app gets approved will soon all be part of your _fastlane_ flow.

## Project Status

- This project is a very early Work In Progress (WIP)
- The idea is to build and iterate with the mobile development community and build this project in the open
- You're welcome to help shape the product, check out [CONTRIBUTING.md](CONTRIBUTING.md) for more info
- Our complete task list is available on our [GitHub board](https://github.com/fastlane/ci/projects/1)

![docs/assets/github_pr_status.png](docs/assets/github_pr_status.png)

## Docs

- [VISION.md](VISION.md): Describes the overall vision and idea of this project, with its core principials
- [docs/SystemArchitecture.md](docs/SystemArchitecture.md): Describes the overall design architecture of `fastlane.ci`, including the controllers, services, data sources and data objects
- [How we store builds and their artifacts](https://github.com/fastlane/ci/issues/40#issuecomment-359507244)

## System Requirements

Requires Ruby 2.3.0 or higher

## Development installation

```sh
bundle install --path vendor/bundle
```

## Local development

```sh
bundle exec rackup -p 8080 --env development
```
If you're having trouble and need to debug, you can add the following environment variables:
`FASTLANE_CI_SUPER_VERBOSE=1` and `DEBUG=1`

`FASTLANE_CI_SUPER_VERBOSE` enables extra logging which includes thread ids, and other non-essential information that could be useful during debugging.

Visit [127.0.0.1:8080](http://127.0.0.1:8080/) to open the login

## Run tests

```sh
bundle exec rspec
```

## Code style

```sh
bundle exec rubocop -a
```
