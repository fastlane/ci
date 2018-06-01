# `features/build_runner`

This directory includes the classes to represent a `BuildRunner`. A `BuildRunner` is responsible for running a given build (e.g. running unit tests) and reporting its status back to the `BuildRunnerService`.

As a user of the classes here, you can register yourself as a listener (`add_build_change_listener`) to be updated in real-time.
