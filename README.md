# fastlane CI

Requires ruby 2.3.0 or higher

## Development installation

```
bundle install --path vendor/bundle
```

## Local development

```
bundle exec rackup -p 8080 --env development
```

Visit [127.0.0.1:8080](http://127.0.0.1:8080/)

## Run tests

```
bundle exec rspec
```

## Code style

```
bundle exec rubocop -a
```
