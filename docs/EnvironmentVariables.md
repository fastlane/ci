# Environment Variables

## Normal operation focused
During the normal operation of fastlane.ci, you'll need a few values. Some values are needed for just the first time setup, while others are required 100% of the time.

`FASTLANE_CI_ENCRYPTION_KEY="key"` - Arbitrary key you decide. This will be used for password encryption. **Note: Do not change after selecting a key value, otherwise there will be decoding issues.** 

`FASTLANE_CI_USER="email@bot.com"` - Email address of the fastlane CI bot account you want to use to update all your commit statuses

`FASTLANE_CI_PASSWORD="password"` - Password of your fastlane CI bot account

`FASTLANE_CI_REPO_URL="https://github.com/your-name/your-ci-config"` - Git URL (https) for the configuration repo you wish the server to use

`FASTLANE_CI_INITIAL_CLONE_EMAIL="email@user.com"` - Email address used for the initial clone for the config repo. **Note: needed just for the first startup of fastlane.ci**

`FASTLANE_CI_INITIAL_CLONE_API_TOKEN="token"` - API token used for the initial clone for the config repo. **Note: needed just for the first startup of fastlane.ci**

## Development focused
`FASTLANE_CI_SKIP_WORKER_LAUNCH` - Don’t launch workers on startup. Useful if you’re debugging UI things or manual processes that don’t need workers.

`FASTLANE_CI_SKIP_RESTARTING_PENDING_WORK` - Skip starting the workers that handle scanning for pending work to be done on startup, eg: don't enque builds for PRs in `pending` status or `open` status

`FASTLANE_CI_THREAD_DEBUG_MODE` - To help you debug any thread-related problems. It allows all workers to start, but anything requiring continuous scheduling will only be allowed to run 1 time and then it will be killed. Allowing you to pry a worker thread without having to worry about it being run again and interrupting your pry session. It also enables verbose output (like `DEBUG=1`).


## Tips and tricks
**Here's what @taquitos has in his `.bash_profile`:**

*Working on UI stuff?*

```bash
alias cidebug='FASTLANE_CI_SKIP_RESTARTING_PENDING_WORK=1 FASTLANE_CI_SKIP_WORKER_LAUNCH=1 FASTLANE_CI_THREAD_DEBUG_MODE=1 bundle exec rackup -p 8080 --env development'
```

*Working on a challenging worker issue?*

```bash
alias cithreaddebug='FASTLANE_CI_SKIP_RESTARTING_PENDING_WORK=1 FASTLANE_CI_THREAD_DEBUG_MODE=1 bundle exec rackup -p 8080 --env development'
```
