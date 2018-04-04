### As a developer, with a PR that fails to build, I want to find the root cause so I can fix it
#### User Journey
1. GitHub notifies user that build failed
1. User accesses logs
1. User looks for a stacktrace with their App’s processes name
1. User finds stacktrace + root cause and begins to fix
1. User commits fix
1. User’s Build passes
1. User merges PR
#### Use Case
1. GitHub has Status update and comment from fastlane on PR indicating that the build failed
1. User opens fastlane ci Web UI
1. Assuming already logged in
1. User opens Project for their Repo + branch
1. User types in their name to filter
1. User clicks on their Build
1. User types in App package name or bundle id into filter
1. User finds stacktrace
1. User fixes bug in their code
1. User builds locally
1. User commits the fix
1. User waits for build to automatically kick off and complete
1. User merges PR now that build is successful