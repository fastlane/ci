# Edit the global fastlane.ci environment variables #

Since `fastlane.ci` should be usable by developers that don't want to use the terminal, we want to make it easy for them to set global environment variables, that are then being used by all projects/builds of `fastlane.ci`. Some examples for why this is useful would be the `JAVA_PATH` and `KEYCHAIN_PATH` ENV variables.
	
### Steps ###
1. In the global settings of `fastlane.ci` the user can click on `Set global environment variables`
1. Similar to how heroku.com allows an easy way to edit env variables in a secure way, the user can add, edit and remove ENV variables
1. There are some instructions on what ENV variables can be used for, with examples of the most common _fastlane_ related ones (currently listed in the fastlane docs https://docs.fastlane.tools/best-practices/continuous-integration/#environment-variables-to-set)
1. Optional: if there are any running builds, we could show a warning to the user, that all builds that have already started at this point, don't have the updated ENV variables yet, and builds that are currently in the queue will have the new ENV context

### Details ###

#### Security ####

All environment variables we manage for the user are treated as secrets. They should be stored fully encrypted, as part of the `ci-config` repo.

#### Distributed builds ####

Once `fastlane.ci` supports distributed builds (multiple Mac workers), this system will automatically distribute those environment variables in a secure way across all nodes.

#### Project specific settings ####

As described in [edit_project_env_variables](./edit_project_env_variables.md), the user can override ENV variables per project.

### Error states ###

[WIP]
