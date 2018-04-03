# Add manual project #

Adding a project should be a very quick and easy process

### Assumptions ###
- fastlane.ci already setup
- User logged in with permissions for the repo they wish to use
- Selected repo already has _fastlane_ setup

### Results ###
At the end of the add project flow, the user will have the following outcome:

- A new project added with specific job trigger conditions
			
### Steps ###
1. User clicks `Add Project`
1. User selects from a `list of organizations` if available
1. User selects from a `list of GitHub repos`
1. A `list of lanes` is displayed
1. User selects `a lane` they wish to use for CI
1. User is given a `list of branches` to select
1. User is given a `list of triggers` to chose from
1. User selects `manual`
1. User clicks `next`
1. User taken to `project details` page where the user is made aware that their project is ready to go, and told that:
    1. they can add more information now, like `description` 
    1. they can edit the name (which was automatically given `repo-name-manual`)
1. User presses `save` button 
1. User is told they can test out the manual trigger now by triggering the job

### Error states ###
[WIP]
