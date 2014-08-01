log = require  "#{process.cwd()}/logger"

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

    # You must listen for the `pageparsed` event on `.parser` before adding new items
    feed.parser.on 'pageparsed', ->
        feed.item {
            title: 'New post',
            date: ...
        }

    feed.load()
###
module.exports = class CachedFeed extends Feed
    # @private {String} lastArticleUrl used internally to detect state
    lastArticleUrl: null

    ###
    @param {String} xml XML string of the cached feed
    @param {Object} config Configuration object passed to the internal `PageParser`, see {PageParser#constructor} for details
    ###
    constructor: (xml, config = { selectors: { } }) ->
        config = _.merge (_.clone config, yes), rss
        config.xmlMode = yes
        config.decodeEntities = yes


        @parser = new PageParser xml, config
        @parser.on 'item', (item) =>
            unless @lastArticleUrl then @lastArticleUrl = item.url
            @item item

        @parser.on 'metadata', (object) =>
            for key, value of object
                @[key] = value

        super config

    ###
    Starts processing the XML and adding cached items
     You should listen for `pageparsed` event on `.parser`.
    ###
    load: ->
        @parser.start()
    ###
    @property {PageParser} an instance of PageParser used to parse the cached XML data
    ###