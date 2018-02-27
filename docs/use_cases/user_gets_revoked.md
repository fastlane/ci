# User gets revoked from a project #

This happens whenever an user gets its permissions over the repository removed. This use case has a side case in where an user might not be able to see any project in the dashboard due to lack of permissions to any project.

## Assumptions ##

- User logged in.
- Dashboard might show a particular list of 1 or more projects which the user has access to.
- **OR**
- Dashboard might show an user-friendly UI where it gets informed that he has no access to any projects on its scope: _"If you think you should be seeing projects here, contact with your organization administrator and request the appropriate permissions."_, or the start point of **creating a new project** use case.

## Side-effects ##

1. _Dashboard_ checks for permissions on reload on every project with the user credentials.
2. If the user tries to access to a project which he has no longer permissions over, it should receive a nice _403 Forbidden_ message about he has no access to the selected project.

## Error states ##

[WIP]
