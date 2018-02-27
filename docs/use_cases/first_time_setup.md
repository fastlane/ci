# fastlane.ci first time setup #

People who have downloaded fastlane.ci will need to be able to get up and running. 

### Assumptions ###
- User setting up fastlane.ci has a GitHub account
- User has a project in GitHub which already uses fastlane
- Setup is occuring on a dedicated High Sierra mac
- User never set up fastlane.ci (no config repo)

### Results ###
At the end of the first time setup, the user will have the following outcomes:

- GitHub bot account
    -  api_token with proper scope
    -  be a member of the proper organization if applicable
- The GitHub account of the developer setting up CI will have:
    -  api_token with proper scope
- fastlane.ci configuration repo 
    -  users.json
      -  bot account included 
        -  GitHub provider credentials (token)
        -  user account included
          -  GitHub provider credentials (token)
    -  projects.json
      - includes the new configuration repo setup `fastlane-ci-config`

### Steps ###
1. User installs fastlane.ci and starts the server
1. Onboarding webpage is launched in browser
1. User is asked to setup a ci bot account with best practices
    1. Explanation of why we need a ci bot account and what it does
    1. Suggestions on email/password/2fa setup
    1. Link to create account opens new window to github
1. Once bot account is setup, user inputs the bot's `email address` and presses `Next`
1. User presented with information about setting up an `api_token`
    1. Examples of scope given and reasons
    1. Told to copy `api_token`
1. User is linked to GitHub area for creating `api_token`
1. Once a `api_token` is obtained, user must input `token` into page, and then presses `Next`
1. Validation occurs on the `email` and `api_token` and if successful, directed to page describing how we store fastlane.ci configuration
    1. The bot info is added to a new `users.json` file in a temporary folder
1. User is presented with an option for creating a `private repo` (if they have permission)
    1. If no permission **_END STATE_** present error
1. Create a `fastlane-ci-config` repo
1. Temporary config folder is now turned into git repo and pushed to repo created in previous step
1. CI clones `fastlane-ci-config` and loads all services
1. Successfully setup bot page, directing user to add their own GitHub account to fastlane.ci and go through add [new user flow](new_user_flow_github.md)
1. On success, user is now logged into the fastlane.ci

### Error states ###
[WIP]