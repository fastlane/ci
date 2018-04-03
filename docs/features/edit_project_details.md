# Edit project details #

Occasionally users will need to update their project's details

### Assumptions ###
- fastlane.ci already setup
- User logged in
- User at dashboard

### Results ###
At the end of the edit project flow, the user will have the following outcome:

- A project will be completely updated with the new details and triggers.
      
### Steps ###
1. At the dashboard, user clicks on a project they wish to edit
1. User taken to `project details`
1. User presses `Edit` button 
1. All fields are editable
1. Lane selection is available with current lane selected
1. Once user is done updating fields they can press `done` or `cancel`
1. Page reverts back to read-only view after `done` or `cancel` pressed

### Error states ###
1. Somebody edits the project while current user is editing it
    1. Solved with optimistic locking

[WIP]
