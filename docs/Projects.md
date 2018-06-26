# Projects

A project in fastlane.ci is defined as a combination of a git repo + a trigger + parameters.

- A git repo can have any number of projects associated
- You can have any number of projects using the same git repo and trigger **type**
- fastlane.ci support multiple [trigger types](https://github.com/fastlane/ci/blob/master/docs/Triggers.md), each of which takes parameters (e.g. what times to run, what branches to build)

Example projects would be

- `Bike App test PRs` (Run unit tests for every PR)
- `Bike App nightly builds` (build a new internal beta every day at 5pm)
- `Bike App weekly public beta` (build a new beta every Friday for external testers)
- `Bike App App Store release` (Manually triggered whenever team wants to ship)

As you can see, the `Bike App` has 4 jobs associated, a total of 3 trigger types.

For each project, the developer selects a `lane` to run for the given project. 
A `lane` is a concept of [fastlane](https://fastlane.tools) that basically defines a build/deploy environment.
Common lanes are `run_tests`, `distribute_beta` or `deploy_to_app_store`. 
