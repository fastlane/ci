### As a developer, with a PR that fails to build, I want to find the root cause so I can fix it
#### Assumptions
* fastlane.ci already set up
* User has Project with test lane and PR trigger.
* User is already logged in
#### User Journey
1. User creates PR
1. User views their PRs failed status
1. User accesses logs and build outputs
1. User locates failure and starts fixing failure
1. User commits fix
1. fastlane.ci rebuilds automatically
1. User’s Build passes
1. User merges PR
#### Use Case
1. User creates PR
1. fastlane.ci automatically launches a build
1. Build fails, fastlane.ci updates the PRs status to failed
1. User loads their PR
1. User views their PRs failed status
1. User clicks on PR status and is linked to their Build
1. User finds failure
1. User fixes bug in their code
1. User builds locally
1. User commits the fix
1. User waits for build to automatically kick off and complete
1. User merges PR now that build is successful