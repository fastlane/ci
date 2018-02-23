# fastlane.ci first time setup #

People who have downloaded fastlane.ci will need to be able to get up and running. 

### Assumptions ###
- User setting up fastlane.ci has a GitHub account
- User has a project in GitHub which already uses fastlane
- Setup is occuring on a dedicated High Sierra mac
- User never set up fastlane.ci (no config repo)

### Results ###
At the end of the first time setup, the user will have the following outcomes:

-  GitHub bot account
	-  api_token with proper scope
	-  proper organization if applicable
-  The GitHub personal account for person setting up ci will have:
	-  api_token with proper scope
-  fastlane.ci configuration repo 
	-  users.json
		-  bot account included 
			-  GitHub provider credentials (token)
		-  user account included
			-  GitHub provider credentials (token)

			
### Steps ###
1. User installs fastlane.ci and starts the server
2. Onboarding webpage is launched in browser
3. User is asked to setup a ci bot account with best practices
  - explanation of why we need a ci bot account and what it does
  - suggestions on email/password/2fa setup
  - Link to create account opens new window to github
4. Once bot account is setup, user inputs the bot's `email address` and presses `Next`
5. User presented with information about setting up an `api_token`
  - Examples of scope given and reasons
  - Told to copy `api_token`
6. User is linked to GitHub area for creating `api_token`
7. Once a `api_token` is obtained, user must input `token` into page, and then presses `Next`
8. Validation occurs on the `email` and `api_token` and if successful, directed to page describing how we store fastlane.ci configuration
  - The bot info is added to a new `users.json` file in a temporary folder
9. User is presented with an option for creating a `private repo` (if they have permission)
  - If no permission **_END STATE_** present error
10. Create a `fastlane-ci-config` repo
11. Temporary config folder is now turned into git repo and pushed to repo created in previous step
12. CI clones `fastlane-ci-config` and loads all services
13. Successfully setup bot page, directing user to add their own GitHub account to fastlane.ci and go through add [new user flow](new_user_flow_github.md)
14. User is directed to login with new user created in previous step

### Error states ###
[WIP]