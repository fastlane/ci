# Access build details #

### Assumptions ###
- fastlane.ci already setup
- at least one repo already setup
- user already selected where to store build artifacts
- user logged in

### Steps ###
1. User selected project
1. User selected a build from the project's build list
1. The (prettified) _fastlane_ build output is already shown in the build details
1. The build detail view includes the following information
    - Build duration
    - Build started at
    - Type of trigger that triggered this particular build
    - Similar issues on GitHub only when the build fails (this is a after 1.0 task as tracked in https://github.com/fastlane/ci/issues/449)
    - Rebuild button for this specific git sha
    - Next to the build output, there is a list of all the available artifact [./access_build_artifacts.md](./access_build_artifacts.md) for more information
