# URL Routes

We want to follow the best practices or already established developer tools, most importantly GitHub (which is also based on good ol' [Rack](https://rack.github.io/))

### Goals

- Consistent URLs, that users can understand (our users are developers)
- Follow best practices of GitHub
- This is a living document, update with samples, references and new roles as we go

### `routes.rb`

Since `fastlane.ci` isn't using Ruby on Rails, we don't have a `routes.rb`. Instead, the mapping lives in each feature controller.
This comes with its own up- and downsides.

### Rules

#### Listing global resources

- `/projects_erb`
- `/users`
- `/settings`

#### Accessing a resource

- `/projects_erb/[project_id]`: Show project details and allow settings to be configured
- `/projects_erb/[project_id]/builds/[build_id]`: Show build details - even though `[build_id]` might be unique, we want to have its parent in the URL also

**More depth**

Sometimes a resource has a view with more details, so we can append `/details` to the URL. We should use the following pattern (to e.g. show more build details)

- `/projects_erb/[project_id]/builds/[build_id]/details`

#### Editing a resource

Basically the same URL as accessing a resource, but with an appended `/edit`

- `/projects_erb/[project_id]/builds/[build_id]/edit`

#### POST URLs

`POST` requests should always be sent to a `/save` endpoint

- `/projects_erb/[project_id]/save`
- `/projects_erb/[project_id]/builds/[build_id]/save`

#### DELETE URLs

`DELETE` requests should always be sent to a `/delete` endpoint

- `/projects_erb/[project_id]/delete`
