# Architecture #
To aid in rapid prototyping we're using a pattern that is similar to MVCS. There are a few significant departures, so we'll just detail the architecture instead of describing the changes.

## Table of Contents:
- [Goals](#goals)
- [Definitions](#definitions)
  * [Views](#views)
  * [View Data Objects](#view-data-objects)
  * [Controllers](#controllers)
  * [Services](#services)
  * [Data Sources](#data-sources)
  * [Data Objects](#data-objects)
- [Anti-Patterns](#anti-patterns)
  * [Use of MVC](#use-of-mvc)
    * [Alternative to MVC](#alternative-to-mvc)
  

## Goals ##
Allow for multiple people to work without stepping over each others commits. Minimize engineer dependencies (nobody sitting around for a merge), and maximize for future open source benefits like cross-geo, weekend warrior, while also being intuitive and easy to maintain. Specifically, the architecture attempts to provide the following: 

- clear separation of responsibilities
- minimal dependencies across the system
- data objects are implicitly immutable
- minimal shared data objects
- minimal shared state
- reduced merge conflicts


## Definitions ##
Let's clear up our shared understanding of the terminology we'll be using so we have a common language to describe things. Below is a list of the layers from UI down to the persistence. Each layer is further from the UI.

### Views ###
Presents data somehow, usually HTML, in this case it will likely take the form of an [erb](http://ruby-doc.org/stdlib-2.3.0/libdoc/erb/rdoc/ERB.html).

### View Data Objects ###
If your view is sufficiently complicated (subjective), you will want to populate it with an object meant to represent the view's state at that moment, instead of passing in a set of variables, you can pass a single object with properties. 

For example: On the **build details** page you might have a **user** object and a **build** object, instead of passing a bunch of properties that live on these two objects to the view, you might want to create a **BuildDetailViewData** object that only contains the fields you will actually be using. 

The primary purpose is to help you become more protected from changes in the underlying **data objects**, and improving the overall testability of the project by not tightly coupling low-level data objects to views.

Furthermore, this creates a very discoverable pattern where, at a glance, you can see exactly what data a view needs by looking at the **view data object**.

### Controllers ###
Controllers query data from a service, and populate a view. If you're used to iOS, this would be a UIViewController subclass. You never talk directly to a data source here, you want to keep this level only concerned with presenting views, routing, and asking a service for very specific data.

### Services ###
Business logic is stored here. If you need to combine multiple data sources or massage data before it can be presented, this is where you should do that. You can think of it as a controller for your data sources.

### Data Sources ###
Where you get data from, where you store it. If you have a database, you'll connect to it in your data source. The data source should have an explicit interface so that you can swap them out. During prototyping, we'll be using mainly json files for storing data, but since each specific data source (for example: `JSONUserDataSource`) will be conforming to a `UserDataSource` interface, you can swap that out with a MySQLUserDataSource. Think of your data source as an API for your underlying storage. You can write custom logic to handle the specifics of your storage technology, but the API should always remain consistent.

### Data Objects ###
These objects are typically returned from [Data Sources](#data-sources). Each object is generally meant to only contain properties, with little-to-no logic. Data objects do not know where they came from, or how to perform any mutating operations. 
Some examples of Data Objects: `Project`, `User`, `GitRepoConfig` and `ProviderCredential`. None of these objects handle their own storage. You use [Services](#services) to query as well as any other [CRUD operation](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete) needed.

## Anti-Patterns ##
With this design, the biggest anti-pattern would be creating a traditional ruby "model" and having it manage its own persistence/querying/[CRUD operation](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete). An example of this would be if you created an object like this:

### Use of MVC ###
What you might be more used to

```ruby
class User
  attr_accessor :id
  attr_accessor :email

  def self.users
    # query for users here
  end

  def save!
    # save this current user
  end
end
```

Don't do that 👆

#### Alternative to MVC ####

##### Utilizing [services](#services), [data sources](#data-sources), and [data objects](#data-objects) #####
Instead, what you want is to utilize [dependency injection](https://en.wikipedia.org/wiki/Dependency_injection) and [services](#services):


```ruby
# this is only set 1 time during app startup
user_service = UserService.new(user_data_source: JSONUserDataSource.new(path: "my_users.json"))

taquitos_user = user_service.login(email: "taquitos@gmail.com", password: "tacos_are_delicious")

# Note: setting first_name here doesn't persist anything
taquitos_user.first_name = "Josh"

# very explicit about what you want, in order to update this user, you must ask a service to do it
user_service.update_user!(user: taquitos_user)
```

This enables us to quickly adopt new data sources, test logic, and not have as many merge conflicts or schema update problems.
