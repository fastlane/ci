# Edit artifact settings of a project  #

`fastlane.ci` supports a flexible system to allow any kind of store options, so that developers can own their data.
For more information on how it works, check out [docs/ArtifactsAndBuilds.md](/docs/ArtifactsAndBuilds.md)

For information on how to access artifacts, check out [access_build_artifacts.md](./access_build_artifacts.md).

### Assumptions ###
- fastlane.ci already setup
- user logged in

### Results ###
The developer added a new artifact provider to a given project. From now on, all build artifacts, including the build output will be stored there, without having changed the existing builds

### Steps ###
1. In the project settings, the user sees what artifact provider is currently being used
1. The user can click on `Replace artifact provider`
    1. If there are no connected artifact providers yet, the user is redirected to [./connecting_a_new_artifact_provider](connecting_a_new_artifact_provider.md)
    1. If there are connected artifact providers, the user can choose one in the list, and have the option to connect a new one (which would redirect the user to [./connecting_a_new_artifact_provider](connecting_a_new_artifact_provider.md))
    1. Sensible defaults are used
1. The user sees the currently set "parameters" of the used artifact provider, and can edit them, this includes:
    - By default fastlane.ci stores all artifacts, this can be changed:
        - Simple ignore list (e.g. `*.ipa`, or `*.tmp`)
    - Option to limit artifact storage by last X days, or last X builds (failures or successful)
        - Option to only keep most recent successful build (like for screenshots)


### Error states ###
[WIP]
