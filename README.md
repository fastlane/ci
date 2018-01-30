# `[WIP] fastlane.ci`

Open source, self hosted, mobile optimized CI powered by [fastlane](https://fastlane.tools) from the same team that built _fastlane_.

- **Git first**: 100% of the configuration files are stored in git, on a server of your choice
- **Configuration files first**: Human readable and editable config files, fully transparent
- **Open source**: Just like _fastlane_, open source and community driven
- **Self hosted**: You should be able to own your CI systems, and scale up as needed
- **Adapters**: Integrate with services you already use, store artifacts where you want them
- **Native fastlane integration**: You already use _fastlane_? `fastlane.ci` will work out of the box for you
- **Mobile first, mobile only**: For now, we focus exclusively on building the best CI system for mobile app devs

For more details on the vision of the project, check out [VISION.md](VISION.md)

## Project Status:

- This project is a very early Work In Progress
- The idea is to build and iterate with the mobile development community and build this project in the open
- You're welcome to help shape the product, check out [CONTRIBUTING.md](CONTRIBUTING.md) for more info

## Docs

- [VISION.md](VISION.md): Describes the overall vision and idea of this project, with its core principials
- [docs/SystemArchitecture.md](docs/SystemArchitecture.md): Describes the overall design architecture of `fastlane.ci`, including the controllers, services, data sources and data objects
- [How we store builds](https://github.com/fastlane/ci/issues/40#issuecomment-359507244)

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
`super_verbose=1` and `DEBUG=1`

`super_verbose` enables extra logging which includes thread ids, and other non-essential information that could be useful during debugging.

Visit [127.0.0.1:8080](http://127.0.0.1:8080/) to open the login

## Run tests

```sh
bundle exec rspec
```

## Code style

```sh
bundle exec rubocop -a
```
