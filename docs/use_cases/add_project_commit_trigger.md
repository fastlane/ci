# Add commit trigger to project #

Adding a commit-based trigger to the project is key for any ci system. We want to be able to monitor specific branches and anytime a commit happens we trigger the `build`.

### Assumptions ###
- User logged in with permissions for the repo they wish to use
- Project already setup, or at the `User is given a list of branches to select` stage of adding a new project.

### Results ###
At the end of the add commit trigger flow, the user will have the following outcome:

- Project will be have a new trigger added.
- Trigger will cause the project to be build when a commit happens on the branch associated with the trigger.
      
### Steps ###
1. *If starting from an existing project*: user selects `add new trigger` button
1. User is given a `list of branches` to select
1. User is given a `list of triggers` to chose from
1. User selects `commit`
1. User clicks `next`
1. User taken to `project details` page where the user is made aware that their project is ready to go
1. User presses `save` button 
1. User is told they can test out the commit trigger now by making a commit to the repository and branch specified by the trigger

### Error states ###
[WIP]
