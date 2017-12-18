#Architecture#
To aid in rapid prototyping we're using a pattern that is similar to MVCS. There are a few significant departures, so we'll just detail the architecture instead of describing the changes.

##Goals##
Allow for multiple people to work without stepping over each others commits. Minimize engineer dependencies (nobody sitting around for a merge), and maximize for future open source benefits like cross-geo, weekend warrior, while also being intuitive and easy to maintain. Specifically, the architecture attempts to provide the following: 

- clear separation of responsibilities
- minimal dependencies across the system
- data objects are implicitly immutable
- minimal shared data objects
- minimal shared state
- reduced merge conflicts


##Definitions##
Let's clear up our shared understanding of the terminology we'll be using so we have a common language to describe things. Below is a list of the layers from UI down to the persistence. Each layer is further from the UI.

###Views###
Presents data somehow, usually HTML, in this case it will likely take the form of an [erb](http://ruby-doc.org/stdlib-2.3.0/libdoc/erb/rdoc/ERB.html).

###View Data Objects###
If your view is sufficiently complicated (subjective), you will want to populate it with an object meant to represent the view's state at that moment, instead of passing in a set of variables, you can pass a single object with properties. 

For example: On the **build details** page you might have a **user** object and a **build** object, instead of passing a bunch of properties that live on these two objects to the view, you might want to create a **BuildDetailViewData** object that only contains the fields you will actually be using. 

The primary purpose is to help you become more protected from changes in the underlying **data objects**, and improving the overall testability of the project by not tightly coupling low-level data objects to views.

Furthermore, this creates a very discoverable pattern where, at a glance, you can see exactly what data a view needs by looking at the **view data object**.

###Controllers###
Controllers query data from a service, and populate a view. If you're used to iOS, this would be a UIViewController subclass. You never talk directly to a data source here, you want to keep this level only concerned with presenting views, routing, and asking a service for very specific data.

###Services###
Business logic is stored here. If you need to combine multiple data sources or massage data before it can be presented, this is where you should do that. You can think of it as a controller for your data sources.

###Data Sources###
Where you get data from, where you store it. If you have a database, you'll connect to it in your data source. The data source should have an explicit interface so that you can swap them out. During prototyping, we'll be using a JSONDataSource, but since we'll be conforming to a DataSource interface, you can swap that out with a MySQLDataSource. Think of your data source as an API for your underlying storage. You can write custom logic to handle the specifics of your storage technology, but the API should always remain consistent.

###Data Objects###
These objects are typically immutable. Data sources return these. Each object is generally meant to only contain properties, with little-to-no logic. Data objects do not know where they came from, or how to perform any mutating operations. 
