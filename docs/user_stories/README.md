# User Stories
## Terminology
* __Repo__ - Repository containing the source code (ex. Git Repository)
* __Project__ - Set of steps or actions that a CI performs relative to a Repo
* __Build__ - Main entity created as a product of a project
* __Branch__ - A version control concept where you can make modification upon a snapshot of master.
* __master__ - The main branch in a repo
* __User Goal__ - A goal that a user has
* __User Story__ - a short description of a feature told from the perspective of a user following the template: _As a < type of user >, I want < some goal > so that < some reason >_.
* __User Journey__ - describes the set of steps a user takes to complete a goal or accomplish a task
* __Critical User Journey__ - is a user journey that is either very common, or very important to get right, or both.
* __Use Cases__ - describe a complete interaction between the software and users
## Goal: I want to debug a build that failed
### [P0: As a developer, with a PR that fails to build, I want to find the root cause so I can fix it and merges](./debug_failed_build.md)