# New user flow #
We want a smooth onboarding experience for developers. Normally we'd opt to use GitHub App authentication. In this case, though, that doesn't technically work for us. The flow requires you to register an App with GitHub, as well as a callback url they can redirect you to once a user is authenticated. Since fastlane.ci is self-hosted, we can’t provide a callback-url to GitHub as part of the auth flow because the CI system is most likely behind a firewall. We also don't want people to have to register their CI system with GitHub.

For now, people will have to create local fastlane.ci accounts and link a user-generated GitHub token to them.

### Assumptions ###
- fastlane.ci already setup
- User already has a GitHub account

### Results ###
At the end of the new user flow, the user will have the following outcomes:

-  fastlane.ci account
  -  linked github `api_token` with proper scope to account

### Steps ###
1. New user webpage explains why an account is needed, `Next` pressed
1. User presented with information about setting up an `api_token`
    1. Examples of scope given and reasons
    1. Told to copy `api_token`
1. User is linked to GitHub area for creating `api_token`
1. Once a `api_token` is obtained, user must input `token` into page, and then presses `Next`
1. Validation occurs on `api_token` and if successful, we use the `api_token` to retrieve their primary email address, and display that. 
1. The user is added to the `users.json` in the `config-repo`
1. Successfully setup new user page

### Error states ###
[WIP]
