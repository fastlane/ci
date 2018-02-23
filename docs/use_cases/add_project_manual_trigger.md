# Add manual project use case #

Adding a project should be a very quick and easy process

### Assumptions ###
- fastlane.ci already setup
- User logged in with permissions for the repo they wish to use
- Selected repo already has _fastlane_ setup

### Results ###
At the end of the add project flow, the user will have the following outcome:

-  A new project added with specific job trigger conditions
			
### Steps ###
1. User clicks `Add Project`
2. User selects from a `list of organizations` if available
3. User selects from a `list of GitHub repos`
4. A `list of lanes` is displayed
5. User selects `a lane` they wish to use for CI
6. User is given a `list of branches` to select
7. User is given a `list of triggers` to chose from
8. User selects `manual`
9. User clicks `next`
10. User taken to `project details` page where the user is made aware that their project is ready to go, and told that:
 -  they can add more information now, like `description` 
 -  they can edit the name (which was automatically given `repo-name-manual`)
11. User presses `save` button 
12. User told they can test out the manual trigger now by triggering the job

### Error states ###
[WIP]
