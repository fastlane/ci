### As a developer, with a PR that fails to build, I want to find the root cause so I can fix it and merges
#### User Journey
1. GitHub notifies user that build failed
2. User accesses logs
3. User looks for a stacktrace with their App’s processes name
4. User finds stacktrace + root cause and begins to fix
5. User commits fix
6. User’s Build passes
7. User merges PR
#### Use Case
1. GitHub has Status update and comment from fastlane on PR indicating that the build failed
2. User opens fastlane ci Web UI
4. Assuming already logged in
5. User opens Project for their Repo + branch
6. User types in their name to filter
7. User clicks on their Build
8. User types in App package name or bundle id into filter
9. User finds stacktrace
10. User fixes bug in their code
11. User builds locally
12. User commits the fix
13. User waits for build to automatically kick off and complete
14. User merges PR now that build is successful