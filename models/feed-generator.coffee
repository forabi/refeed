log = require("#{process.cwd()}/logger")

EventEmitter = require('events').EventEmitter

_          = require 'lodash'
async      = require 'async'
fs         = require 'fs'
url        = require 'url'

cheerio    = require 'cheerio'

Feed       = require 'rss'
CachedFeed = require './cached-feed'
request    = require 'request'

PageLoader = require './page-loader'
PageParser = require './page-parser'

defaults   = require '../defaults.json'

###
This model takes care of all the tasks required to generate the raw XML data
that are then written to a file. Note that it does not directly write the file,
instead it emits a 'feedgenerated' event with the XML string.

@example
    generator = new FeedGenerator 'hindawi', {
        host: 'http://www.hindawi.org/',
        url: 'http://www.hindawi.org/books',
        language: 'ar',
        selectors: {
            ...
        }
    }, './feeds/hindawi.xml'

    generator.on 'feedgenerated', (xml) ->
        fs.writeFile xml, done

    generator.on 'initialized', ->
        generator.generate()

    generator.initialize()


@event initialized - Emitted when the generator has checked for a cached feed and finished processing it.

@event feedgenerated - Emitted when the whole XML data is ready

@event error

###
module.exports = class FeedGenerator extends EventEmitter
    ###
    @param feedId {String} the unique identifier of the feed to generate
    @param config {Object} Feed configuration object
    @param cachedXMLPath {String} Path to an XML file representing a cached version of the feed
    ###
    constructor: (@feedId, config, @cachedXMLPath) ->
        if 'string' is typeof config.inherits
            log 'debug', "Feed #{feedId} inherits prototype #{config.inherits}"
            config =
                _.merge config, require "../prototypes/#{config.inherits}"

        if config.url.href then config.url = url.parse config.url.href

        config.site_url = url.format config.url

        host = _.pick config.url, 'protocol', 'host', 'auth'
        config.host = url.format host

        log 'verbose', "Host is #{config.host}"

        @config = _.defaults config, defaults

        @feedConfig = @config

    ###
    This method checks for a cached feed and waits until the cache is processed and
    all cached items are added to the new `@feed`.
    You should call this after adding listeners to the `initialized` event.
    ###
    initialize: ->
        try
            xml = fs.readFileSync(@cachedXMLPath).toString()
            @feed = new CachedFeed xml, @feedConfig
            @feed.on 'ready', =>
                @emit 'initialized'
                log 'info', "Reusing cached feed file #{@cachedXMLPath}"
                log 'debug', "Cached feed XML length is #{xml.length}"
                log 'info', "Last cached article is #{@feed.lastArticleUrl}"

            @feed.load()

        catch e
            @feed = new Feed @feedConfig
            @emit 'initialized'
            switch e.code
                when 'ENOENT'
                    log 'warn', "Feed #{@feedId} is not cached,
                    was expected at #{@cachedXMLPath}"
                else
                    log 'error', 'Something went wrong while loading the cached feed,
                    rebuilding...', e.toString()

    ###
    @property [Number] The maximum number of pages to load, each page instantiates a new `PageLoader`
    ###
    maxPages: Infinity

    ###
    @property [Boolean] Whether to honor the `maxPages` limit even in cases where there are more pages to load until `lastArticleUrl` is matched. Setting this to `true` may cause some articles to be missing from the feed.
    ###
    forceLimit: yes


    ###
    Generates the feed as XML, emits a `feedgenerated` event on finish with the XML data
    ###
    generate: ->
        pageUrl = @config.url.href || url.format @config.url
        loaded           = 0
        loadedItems      = []
        totalCachedItems = @feed.items.length || 0
        newItems         = []
        parser           = null

        noMoreArticles = =>
            (typeof pageUrl isnt 'string') or
            (loaded >= @maxPages and
                (@forceLimit or @feed.lastArticleUrl is null)) or
            (_.contains loadedItems, @feed.lastArticleUrl) or
            (!!parser and not parser.hasNext)

        end = (err) =>
            return @emit 'error', err if err

            # This should fix order when items have no date specified
            @feed.items = Array::concat newItems, @feed.items

            xml = @feed.xml()
            log 'verbose', 'Feed is ready be written!'
            @emit 'feedgenerated', {
                xml,
                totalNew: (@feed.items.length || 0) - totalCachedItems
            }

        loadPage = (done) =>
            log 'info', "Loading page ##{loaded + 1} (#{pageUrl})"

            loader = new PageLoader pageUrl
            loader.on 'pageloaded', (html) =>
                log 'debug', 'PageLoader finished', pageUrl, html.length
                parser = new PageParser html, @config

                parser.on 'error', (err) ->
                    done err

                parser.on 'metadata', (object) =>
                    log 'debug', 'Got metadata:', object
                    for key, value of object
                        if value and not @feed[key]
                            @feed[key] = value

                parser.on 'item', (item) =>
                    if not item.url
                        return @emit 'error', new Error 'NO_ITEM_URL'

                    exists =
                        _.some @feed.items, (i) ->
                            i.url is item.url

                    if not exists
                        newItems.push _.defaults item, (
                            categories: []
                            enclosure: no
                            title: ''
                        )
                        log 'debug', 'Added new item:',
                            _.omit item, 'description'
                    else
                        log 'debug', 'Item already exists in
                        cached feed', item.url

                    loadedItems.push item.url

                parser.on 'pageparsed', ->
                    loaded += 1
                    if parser.hasNext
                        pageUrl = parser.nextPage
                    done()

                parser.start()

            loader.on 'error', (err) ->
                log 'error', "Error while loading page #{pageUrl}", err
                done err

            loader.load @config

        async.until noMoreArticles, loadPage, end