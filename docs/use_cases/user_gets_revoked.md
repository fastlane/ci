# User gets revoked from a project #

This happens whenever an user gets its permissions over the repository revoked. This use case has a side case in where an user might not be able to see any project in the dashboard due to lack of permissions to any project.

## Assumptions ##

- User logged in.
- User at dashboard.

## Steps ##

1. If the user has no create permissions, and there are no projects, the dashboard might show an user-friendly UI where it gets informed that he has no access to any projects on its scope: _"If you think you should be seeing projects here, contact your GitHub administrator and request the appropriate permissions."_.
2. If the user has create permissions, but no projects yet, the dashboard might show information which triggers the start point of **creating a new project** use case.
3. If the user is at project details link, but has no access, they see a message about the lack of permissions over the selected project.

## Error states ##

[WIP]
