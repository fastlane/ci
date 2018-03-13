# Environment Variables

`FASTLANE_CI_SKIP_WORKER_LAUNCH` - Don’t launch workers on startup. Useful if you’re debugging UI things or manual processes that don’t need workers.

`FASTLANE_CI_SKIP_RESTARTING_PENDING_WORK` - Skip starting the workers that handle scanning for pending work to be done on startup, eg: don't enque builds for PRs in `pending` status or `open` status

`FASTLANE_CI_THREAD_DEBUG_MODE` - To help you debug any thread-related problems. It allows all workers to start, but anything requiring continuous scheduling will only be allowed to run 1 time and then it will be killed. Allowing you to pry a worker thread without having to worry about it being run again and interrupting your pry session. It also enables verbose output (like `DEBUG=1`).


**Here's what @taquitos has in his `.bash_profile`:**

*Working on UI stuff?*

```bash
alias cidebug='FASTLANE_CI_SKIP_RESTARTING_PENDING_WORK=1 FASTLANE_CI_SKIP_WORKER_LAUNCH=1 FASTLANE_CI_THREAD_DEBUG_MODE=1 bundle exec rackup -p 8080 --env development'
```

*Working on a challenging worker issue?*

```bash
alias cithreaddebug='FASTLANE_CI_SKIP_RESTARTING_PENDING_WORK=1 FASTLANE_CI_THREAD_DEBUG_MODE=1 bundle exec rackup -p 8080 --env development'
```
