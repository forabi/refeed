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
    feed = new CachedFeed fs.readFileSync('some.xml').toString(), {
        title: ...
        url: ...
        description: ...
        selectors: {
            title: ...,
            ...
        }
    }

    # You must listen for the end event on `parser` before adding new items
    feed.parser.on 'end', ->
        feed.item {
            title: 'New post',
            date: ...
        }

    feed.load()
###
module.exports = class CachedFeed extends Feed
    # @private {String} lastArticleUrl used internally to detect state
    lastArticleUrl: null

    constructor: (xml, config) ->
        config = _.defaults (_.clone rss, yes), config
        config.xmlMode = yes
        config.decodeEntities = yes


        @parser = new PageParser xml, config
        @parser.on 'item', (item) =>
            unless @lastArticleUrl then @lastArticleUrl = item.url
            @item item

        super config

    load: ->
        @parser.start()
    ###
    @property {PageParser} an instance of PageParser used to parse the cached XML data
    ###