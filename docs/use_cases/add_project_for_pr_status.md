# Add project to monitor a repo to set the build status for PRs #

This is the most common use-case for setting up CI: a development team wants to make sure the tests succeed before merging a PR.
Therefore adding a project for PR status should be a very quick and easy process

### Assumptions ###
- fastlane.ci already setup
- User logged in with permissions for the repo they wish to use
- Selected repo already has _fastlane_ setup

### Results ###
At the end of the add project flow, the user will have the following outcome:

- A new project added with specific job trigger conditions
- All new PRs on the selected repos are now being tested by `fastlane.ci`
			
### Steps ###
1. User clicks `Add Project`
1. User selects from a `list of organizations` if available
1. User selects from a `list of GitHub repos`
1. A `list of lanes` is displayed
1. User selects `a lane` they wish to use for CI. If a lane called `test` is available, it is already highlighted
1. User is given a `list of triggers` to chose from
1. User selects `Pull Requests`
1. User clicks `next`
1. User taken to `project details` page where the user is made aware that their project is ready to go, and told that:
    1. they can add more project information, like a `description` 
    1. they can edit the name (which was automatically given `repo-name-manual`)
1. User presses `save` button 
1. If there are open PRs on the selected repo
    1. `fastlane.ci` tests the setup on the most recent one, and shows the real-time output to the user
    1. If the build was successful, the setup is complete, and `fastlane.ci` tests all remaining open PRs
    1. On build failure, the user is shown enough information about the error, and asks the developer to submit a new PR with an updated (working) `Fastfile` configuration
1. If there are no open PRs, _fastlane_ will use the most recent commit on the default branch (usually `master`) and see if the tests pass
    1. If the build was successful, the setup is complete
    1. On build failure, the user is shown enough information about the error, and asks the developer to submit a new PR with an updated (working) `Fastfile` configuration
  

### Error states ###
[WIP]
