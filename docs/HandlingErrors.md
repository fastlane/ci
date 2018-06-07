# Handling errors

## Background

Many different errors can happen at various different points. Having a system to effectively present errors and the details needed to know what to do, and when, is critically important

## Error situations

1. Something broke, and it might be transient, you can try that action again
1. Some 3rd party dependency failed, and you’ll need to figure out what to do (e.g. GitHub is down, or Xcode couldn't be installed)
1. You hit a fastlane.ci or fastlane bug

Some errors are recoverable by just retrying (we do that automatically for things that make sense). Some are recoverable only when somebody logs into the box and fixes the problem. Some problems are not recoverable at all.

This only applies to ci errors (not build errors), some specific examples: if we lost access to something (Google Cloud, GitHub, etc), if something crashed, or `xcode-version` tool doesn't exist. These are all things we need somebody to intervene to fix. Furthermore, we could separate out the errors/warnings by whether we experienced them in the fastlane.ci server process, or build runner process.

The notifications could be a banner of some sort, so it wouldn't fully interrupt your workflow. You could continue to do whatever you were doing.

## Presenting Errors

Current thinking about errors, they:

1. Show up and stay around until dismissed on a given page, e.g. fastlane broke on this build, but if you want, you can retry it, but you only want this to persist on the project build page
1. Show up and stay around until dismissed on all pages e.g. GitHub is down and you should see that message on any page you go to
1. If you are on a different page, they interrupt your current operation with a link to the page experiencing the error. E.g. a build failed due to fastlane error, but you're currently on the dashboard.

## Information useful to display

1. Human-readable description of what happened, e.g. `fastlane encountered an error running the gym step`
1. A link to GitHub where they can see issues that have similar errors
1. A clear call-to-action, e.g. a button to rebuild
1. Extra detailed description with some extra, less friendly debugging output which could assist in filing a bug
1. Ability to file an issue for fastlane.ci or fastlane problems

## Persisting errors

It would be helpful to have a running list of errors that were encountered so people can better debug their problems.
