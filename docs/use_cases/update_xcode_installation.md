# Update Xcode installation #

Xcode doesn't support proper versioning like other development environments do. The goal with `fastlane.ci` is to make it easy as possible for the user to upgrade their CI system to run multiple versions of Xcode in parallel depending on the branch. This allows development team to work on a `swift-x` migration branch to test Xcode-`X` features without having to break the build for the remaining branches.

To list, manage and install Xcode release, we make use of the [xcode-install gem](https://github.com/krausefx/xcode-install), which exposes all the features we need to implement this use-case.

### Assumptions ###
- fastlane.ci already setup
- at least one repo already setup
- tests are green for the given repo
- user logged in

### Open questions ###

We don't know yet how we're gonna ask for the root password of the macOS user. Unfortunately Xcode requires it during the installation. 
- Asking for it via the web UI feels kind of sketchy
- Asking for it via the terminal assumes we have a terminal, with the plan for `fastlane.ci` Mac app we might not have an interactive terminal, as we don't necessarily want fastlane.ci users to have to use the terminal
- Asking for the admin password on the first launch of fastlane.ci feels wrong, and at this point we didn't gain the trust from the user yet
- Trigger the admin dialog via the native Mac UI requires access to the Mac, which might not have a display connected when it runs headless

It might be worth investigating again if there is a way to install Xcode without admin permission. 

### Results ###

The developer is able to select a new version of Xcode for a specific branch, a specific project, or set a new system default. The installation should happen without the user having to use the terminal or the App Store.

### Steps ###

##### Specific branch #####
The user can only change the Xcode version after a build fails, we don't need a UI otherwise. Since this is all stored as JSON config files, the user could always change it there directly if necessary.

1. Developer starts new `swift-x` branch and pushes to git remote
1. `fastlane.ci` build fails due to new Swift syntax
1. `fastlane.ci` shows build failure and offers to use a different version of Xcode
1. Developer gets a list of available Xcode versions, including pre-releases
1. Developer hits `Save` button, and the new version of Xcode is being installed (this might take up to an hour, we should warn the user about the installation time here)
1. After the Xcode installation is finished, a new build is automatically triggered

##### Specific project #####

1. In the project settings, the user can select a version of Xcode, all available versions, including pre-releases are listed there
1. After selecting a new Xcode version, the Xcode version is saved in the project's JSON configuration, and the installation of Xcode is triggered (this might take up to an hour)
1. After the installation is finished, a new build for the default branch (usually `master`) is triggered.

The above use-case could be even further improved by changing the order slightly, however it does add more complexity to the implementation, so we should start with the first one, and remove the first use-case once we had the time to finish the second one.

1. In the project settings, the user can select a version of Xcode, all available versions, including pre-releases are listed there
1. After selecting a new Xcode version, the installation of Xcode is triggered
1. Once the installation is complete, a build in `master` is triggered, depending on the build status:
	1. If the build is green, the new Xcode version is stored in the project's JSON configuration
	1. If the build is red, the new Xcode version isn't stored in the JSON configuration yet, and we tell the user to use a new branch to try to get the build to green

The second use-case allows to have `master` stay green for the whole time.

##### System wide #####

- As soon as a new public Xcode release is available (or GM), `fastlane.ci` shows a notification with a link to `Upgrade to Xcode x.xx`
- This triggers the installation of the new version of Xcode (this might take up to an hour)
- Once the installation is triggered, `fastlane.ci` will tell the user a rough estimate of how long the installation will take
- Once the installation is complete, we trigger a notification
- The user is then guided through upgrading their projects, by showing a list of projects, and linking directly to the project settings to follow the `Specific project` use-case.

In general, this use-case is really just a helper to remind people to upgrade to the new version of Xcode, it doesn't actually do more.

### Error states ###

If the installation fails, we should show the raw output, error information + stack trace of `xcode-install`, to help the user resolve the issue.
