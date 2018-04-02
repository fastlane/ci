# Access project details #

### Assumptions ###
- fastlane.ci already setup
- User logged in
- User at dashboard
- At least one project set up
      
### Steps ###
1. At the dashboard, user clicks on a project they wish to edit
1. User taken to `project details`
    - Show project name
    - Be able to rebuild a build without opening specific builds
    - Can access project settings (if user has write access to the repo only)
    - Metadata: e.g. repo details, last successful build, last failed build
    - Trigger a build manually
    - Show last commit and its build status
    - Show recent builds and their status
    - [Optional] Show active branches and their status
