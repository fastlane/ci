# New user flow #

fastlane.ci is a multiuser system. Currently we can't use any GitHub api that requires a callback, so we can't use GitHub Auth. For now, people will have to create local fastlane.ci accounts and link their GitHub token to them.

### Assumptions ###
- fastlane.ci already setup
- User already has a GitHub account

### Results ###
At the end of the new user flow, the user will have the following outcomes:

-  fastlane.ci account
	-  linked github `api_token` with proper scope to account
			
### Steps ###
1. New user webpage explains why an account is needed, `Next` pressed
2. User is asked for email address associated with GitHub account
3. User presented with information about setting up an `api_token`
  - Examples of scope given and reasons
  - Told to copy `api_token`
4. User is linked to GitHub area for creating `api_token`
5. Once a `api_token` is obtained, user must input `token` into page, and then presses `Next`
6. Validation occurs on the `email` and `api_token` and if successful, the user is added to the `users.json` in the `config-repo`
7. Successfully setup new user page

### Error states ###
[WIP]
