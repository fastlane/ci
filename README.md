# fastlane CI

Open source, self hosted, mobile optimized CI powered by [fastlane](https://fastlane.tools).

## Docs

- [VISION.md](VISION.md): Describes the overall vision and idea of this project, with its core principials
- [docs/SystemArchitecture.md](docs/SystemArchitecture.md): Describes the overall design architecture of `fastlane.ci`, including the controllers, services, data sources and data objects

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

Visit [127.0.0.1:8080](http://127.0.0.1:8080/)

## Run tests

```sh
bundle exec rspec
```

## Code style

```sh
bundle exec rubocop -a
```
