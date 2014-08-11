log = require  "#{process.cwd()}/logger"

EventEmitter = require('events').EventEmitter

_            = require 'lodash'
Feed         = require 'rss'
PageParser   = require './page-parser'
rss          = require '../prototypes/rss.json'

###
A CachedFeed instance handles XML data of a previous version of
the feed and automatically prases and inserts the existing items
on intialization. It should be used as a replacement for the standard
feed prototype whenever an XML file for the feed exists. New items can
be added as usual using the `Feed#item` method.

@example
    xml = fs.readFileSync('some.xml').toString()

    feed = new CachedFeed xml, {
        title: ...
        url: ...
        description: ...
        selectors: {
            title: ...,
            ...
        }
    }

    # You must listen for the `ready` event before adding new items
    feed.on 'ready', ->
        feed.item {
            title: 'New post',
            date: ...
        }

    feed.load()

@event ready - Emitted when all cached metadata and items have been parsed and added
###
module.exports = class CachedFeed extends Feed
    ###
    @property {String} (read-only)
    ###
    lastArticleUrl: null
    ###
    @param xml {String} XML string of the cached feed
    @param config {Object} Configuration object passed to the internal `PageParser`, see {PageParser#constructor} for details
    ###
    constructor: (xml, config = { selectors: { } }) ->
        config = _.merge (_.clone config, yes), (_.clone rss, yes)
        delete config.selectors.fullPage
        config.xmlMode = yes
        config.decodeEntities = yes

        @_event_emitter = new EventEmitter
        @_parser = new PageParser xml, config
        @_parser.on 'item', (item) =>
            unless @lastArticleUrl then @lastArticleUrl = item.url
            @item item

        @_parser.on 'metadata', (object) =>
            for key, value of object
                @[key] = value

        @_parser.on 'pageparsed', =>
            @_event_emitter.emit 'ready'
            # done()

        super config

    ###
    Starts processing the XML and adding cached items
     You should listen for `ready` event on the CachedFeed instance.
    ###
    load: ->
        @_parser.start()

    ###
    Adds an event listener on the internal page parser
    @param event {String} Only `'ready'` is currently accepted
    @param fn {Function} Function to call
    ###
    on: (event, fn) ->
        @_event_emitter.on event, fn