reFeed
===========
A service that offers RSS feeds for websites that do not natively offer them.

reFeed is composed of two main components, the core and the client.

Core
-----------
The core is the engine that takes care of fetching, caching and updating the RSS feeds. Each task is handled by a standalone model:

* a `PageLoader` is responsible for requesting the webpage located at a specific `url` and returning the `String` representation of the response body.
* a `PageParser` is instantiated with the `html` data and other `config` data to parse the webpage and try to find a set of items that can be recognized as articles. The rules a `PageParser` recognizes articles are defined on a per-feed basis as a collection of CSS selectors. This may be extended in the future to handle complex page layouts that require more sophisticated ways of parsing. For an example of a feed configuration file, take a look at [json/hindawi.json](json/hindawi.json)
* a `FeedGenerator` takes a `feedId`, a `config` object, and an optional `xmlFile` argument that represents a path to cached version of a feed (`feedId`). `FeedGenerator` makes use of the cached version so that the engine does not have to fetch the whole website every time a few articles are added. It may instantiate one or more `PageLoader`s and `PageParser`s.


### Life cycle

* The core looks for `feedId`s that require regenerating (using, for example, a query to a mongo database that stores the required data)
* Instantiate a `FeedGenerator` for each `feedId` that is returned from the query
* Listen to the `end` event on `FeedGenerator` instances and write corresponding XML files to a specific directory
* Update the last check time of each feed in the database
* A static file server serves the XML files

Client (not implemented yet)
-----------------------------
The client part of reFeed provides a usable interface that facilitates searching, creating and fetching of generated feeds.

### Usage scenario

* The home page of the client is a simple webpage with a Google-like search box. The user uses that box to find an already generated feed based on its website URL, title, description or category.

    a. If one match is found, the user is redirected to that feed.
    b.  If more than one match are found, a list of the matches is displayed with title, description and website URL for each match.
    c. If nothing is found, and the input matches a valid URL pattern, the client tries to generate/find at least one feed on that URL. The results are then display in a similar way to the one described in a or b.