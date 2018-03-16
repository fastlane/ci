# `ci-config` repo

## Where is the source of truth when it comes to configuration?

1. `ci-config` git remote
1. The locally cloned `ci-config` repo
1. The GitHub PR build status (only applies to build status)

Meaning, that if a user changes e.g. a project setting, we update the JSON file locally, commit the change, and try to push to the git remote. If the push fails, a user has manually updated the configuration file, meaning it might be enough to `git pull` and `git push` again. However if the `git pull` causes merge conflicts, we'll have to show an error message to the user, telling that to resolve the merge conflict, or we could just discard the local changes, and take whatever the remote tells us. In the future, we could provide a UI for this to ask the user what to do.

## We now define a few assumptions for fastlane.ci for the `ci-config` repo:
- The `ci-config` repo is only updated by a single node, being the master `fastlane.ci` machine. Even if the developer has a fleet of 100 Macs, they all communicate with the master, this ain't a decentralized blockchain
- The only reason why the `ci-config` repo might be changed outside of the `fastlane.ci` process on the Mac, is when the user manually edits a file, which is a valid use-case. By storing all configurations in version control, giving the user the power of those files is one of the reasons why we decided to use git and JSON.
- It's enough to `git pull` every few minutes on the `fastlane.ci` main machine on the background worker (something we already do AFAIK), `git pull` takes less than a second, so it's fine to do that often in the background. Users won't expect a JSON file change to **instantly** show up on their local server, they'd either try to restart the server (which would work as we pull on startup) or wait for a few minutes
