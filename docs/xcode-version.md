# `.xcode-version`

## Introduction

This is a proposal for a new standard for the iOS community: a text-based file that defines the Xcode version to use to compile and package a given iOS project.

This will be used natively in [fastlane.ci](https://fastlane.ci) with the new [Xcode management feature](https://github.com/fastlane/ci/pull/819), however it's designed in a way that any tool in the future can pick it up, no matter if it's Ruby based, Swift, JavaScript, etc.. 

Similar to the [.ruby-version file](https://en.wikipedia.org/wiki/Ruby_Version_Manager), the `.xcode-version` file allows any CI system or IDE to automatically install and switch to the Xcode version needed for a given project to successfully compile your project.

Tools like [xcode-install](https://github.com/krausefx/xcode-install) allow an automatic installation of new or old Xcode versions.

## File name

The file name must always be `.xcode-version`

## File location

The file must be located in the same directory as your Xcode project/workspace

## File content

The file content must be a simple string in a text file. The file may or may not end with an empty new line, the parser is responsible for stripping out the trailing `\n` (if used)

### Sample files

To define an official Xcode release

```
9.3
```

```
7.2.1
```

You can also use pre-releases using the following syntax

```
9.4b2
```

**Note**: Be aware that pre-releases will be taken down from Apple's servers, meaning that it won't allow you to have fully reproducible builds as you can't download the Xcode release once it's gone.

It is recommended to only use non-beta releases in an `.xcode-version` file to have fully reproducible builds that you'll be able to run in a few years also.

## Comparing versions

### Ruby

In Ruby, comparing the file content is really easy:

#### Parse the version

```ruby
Gem::Version.new("9.2b3") # => <Gem::Version "9.2b3">
```

#### Compare

```ruby
# Compare pre-releases
Gem::Version.new("9.2b3") > Gem::Version.new("9.2b1") # => true

# Check if 2 versions are the same
Gem::Version.new("9.2b3") == Gem::Version.new("9.2b3") # => true

# Check if public version is higher than the pre release for the same version
Gem::Version.new("9.2") > Gem::Version.new("9.2b5") # => true

# Check if 10 is larger than 9
Gem::Version.new("10.4.5") > Gem::Version.new("9.1.2") # => true

# Check if 8.0 is the same as 8
Gem::Version.new("8.0") == Gem::Version.new("8") # => true
```
