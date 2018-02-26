# Update fastlane.ci #

Similarly to [fastlane](https://fastlane.tools) we aim to ship updates regularly to have incremental changes, instead of a few larger updates per year.

The installation methods for `fastlane.ci` aren't decided yet, so this use case describes how the automatic updates would work on a RubyGems based installation.

Similar to the [update_fastlane](https://docs.fastlane.tools/actions/update_fastlane/) action in _fastlane_, we don't want to force people to use an auto-updater system. 
Instead we want to offer an easy way to opt-in to auto-update, and make it the recommend way, while still putting the user in control.

### Assumptions ###
- fastlane.ci is installed via RubyGems

### Results ###
[Empty]

### Steps ###
- User starts onboarding
- As one of the last steps, the user is asked if they want to let `fastlane.ci` automatically itself
- `fastlane.ci` periodically checks for new versions, by using similar code to the [update_fastlane](https://docs.fastlane.tools/actions/update_fastlane/) action
- After a successful update, `fastlane.ci` might show an updated message somewhere in the notifications screen (to be determined if we really want to do this)
- If the updated fails, the user is notified through the CI notifications, with instructions on how to manually trigger the update

### Long term plans ###
The long term plan is to offer a `fastlane.app` Mac app, that a developer can download and install on their Mac. 
This package includes `fastlane.ci` with all its dependencies. By having this wrapper, the automatic update system could be part of that.

### Error states ###
[WIP]
