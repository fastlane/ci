# Triggers

## Background

The heart of any CI system is a set of triggers that kick off the builds when certain events happen, or on a schedule

## Triggers and their events

The events that we support at launch are:

- `Nightly Trigger`: Build project builds on a schedule
- `Commit Trigger`: Build after a commit is made
- `PR Trigger`: Build after a PR is made, or a commit is added to a PR
- `Manual Trigger`: Build after somebody presses the `Build` button

For the initial release of fastlane.ci, our focus is:
- Simple: Keeping things as simple as possible, and very easy to understand
- Focused: Only worry about the primary scenarios of why people want to setup fastlane.ci
- Flexible: developers can customize those further by modifying the JSON file manually. At least for a 1.0 that should be enough

As a result, the `Add a new project step` has the following options:
- Build every commit (for a specific branch, or all)
- Build only PRs
- Build nightly (at a given time)
- Build manually only (for a specific branch)

For the top 3 build triggers, we'd also automatically add the `manual trigger`. The primary reason is that we always want people to be able trigger a build manually. This is crucial especially during the setup, as most likely the first [x] builds won't succeed

If the developer selects `nightly`, they get the extra selection for the time. All other trigger types don't have any additional options (beyond branch selection for some)
