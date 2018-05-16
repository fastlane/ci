# fastlane.ci first time setup #

People who have downloaded fastlane.ci will need to be able to get up and running. 

### Assumptions ###
- User setting up fastlane.ci has a GitHub account
- User has a project in GitHub which already uses fastlane
- Setup is occurring on a dedicated High Sierra Mac
- User didn't set up fastlane.ci before (no ci-config repo)

### Results ###
At the end of the first time setup, the user will have the following outcomes:

- GitHub bot account
    -  api_token with proper scope
    -  be a member of the proper organization if applicable
- The GitHub account of the developer setting up CI will have:
    -  api_token with proper scope
- `ci-config` repo 
    -  `users.json`
        -  Bot account included 
            -  GitHub provider credentials (personal acces token)
        -  User account included
            -  GitHub provider credentials (personal acces token)
    -  `projects.json`
        - includes the new configuration repo setup `fastlane-ci-config`

### Steps ###
1. User installs fastlane.ci and starts the server
1. Onboarding webpage is launched in browser
1. User is asked to connect their GitHub personal access token
    1. Explanation of why we need a personal access token
    1. Explanation of scope of access token
    1. Link to GitHub to create an personal access token
    1. Text box for personal access token and read-only email text box (which is automatically filled in from GitHub)
    1. After submitting the information, validation occurs
        1. On success, we use the access token to retrieve their email
        1. Display email that we will use
        1. On Next, information added to temporary `users.json`
        1. Error information on failure
1. User is asked to setup a **CI bot account** with best practices
    1. Explanation of why we need a ci bot account and what it does
    1. Suggestions on email/password/2fa setup
    1. Explanation of scope of access token
    1. Link to GitHub to create an personal access token
    1. Text box for personal access token and email (which is automatically filled in from GitHub)
    1. After submitting the information, validation occurs
        1. Redirect on success, information added to temporary `users.json`
        1. Error information on failure
1. Onboarding process to help link or create a `private repo` for the `ci-config`
    1. Explanation on why we need a repo
    1. Text box for entering an existing `private repo` for the config, or leave blank to create one
    1. If user gave permission to create new repo, offer one-click button to create it for them
    1. If user didn't give permission to create new repo, link to GitHub URL
    1. After repo is available, automatically invite the bot to repo if permission is there, otherwise tell user how to add the bot
1. Temporary config folder is now turned into git repo and pushed to repo created in previous step
1. CI clones `fastlane-ci-config` and loads all services
1. On success, user is now logged into the fastlane.ci
1. User starts with the [/docs/use_cases/add_project_for_pr_status.md](/docs/use_cases/add_project_for_pr_status.md) flow, that shows a list of all organizations and repos the user has access to

### Error states ###
[WIP]
