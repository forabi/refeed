logger = require process.cwd() + '/logger'

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
instead it emits an 'end' event with the XML string.

@example
    generator = new FeedGenerator('hindawi', {
        host: 'http://www.hindawi.org/',
        url: 'http://www.hindawi.org/books',
        language: 'ar',
        selectors: {
            ...
        }
    }, './feeds/hindawi.xml')

    generator.on 'end', (xml) ->
        fs.writeFile(xml, done)

    generator.generate()


@event end - This event is emitted when the whole XML data is ready
    @type {Object}

###
module.exports = class FeedGenerator extends EventEmitter
    ###
    @param {String} feedId the unique identifier of the feed to generate
    @param {Object} config Feed configuration object
    @param {String} cachedXMLPath Path to an XML file representing a cached
    version of the feed
    ###
    constructor: (@feedId, @config, cachedXMLPath) ->
        self = this
        feedConfig = _.extend @config, { site_url: config.url }

        if 'string' is typeof @config.inherits
            logger.info "Feed #{feedId} inherits prototype #{config.inherits}"
            config =
                _.defaults config, require "../prototypes/#{config.inherits}"

        config = _.defaults config, defaults

        try
            xml = fs.readFileSync(cachedXMLPath).toString()
            @feed = new CachedFeed xml, feedConfig
            logger.info "Reusing cached feed file #{cachedXMLPath}"
            logger.info "Cached feed XML length is #{xml.length}"
            logger.info "Last cached article is #{@feed.lastArticleUrl}"
        catch e
            @feed = new Feed feedConfig
            logger.info "Something went wrong while loading the cached feed,
            was expected at #{cachedXMLPath}", e

    ###
    @property [Number] The maximum number of pages to load,
    each page instantiates a new `PageLoader`
    ###
    maxPages: Infinity

    ###
    @property [Boolean] Whether to honor the maxPages limit even in cases
    where there are more pages to load until lastArticleUrl is matched.
    Setting this to `true` may cause some articles to be missing from the feed.
    ###
    forceLimit: yes


    ###
    Generates the feed as XML, emits an `end` event on finish with the XML data
    ###
    generate: ->
        pageUrl        = @config.url
        loaded         = 0
        articles       = []
        parser         = null

        noMoreArticles = =>
            (typeof pageUrl isnt 'string') or
            (loaded >= @maxPages and
                (@forceLimit or @feed.lastArticleUrl is null)) or
            (_.contains articles, @feed.lastArticleUrl) or
            (!!parser and not parser.hasNext)

        end = (err) =>
            return @emit 'error', err if err
            xml = @feed.xml()
            logger.info 'Feed is ready be written!'
            @emit 'end', xml

        loadPage = (done) =>
            logger.info "Loading page ##{loaded + 1} (#{pageUrl})"

            loader = new PageLoader pageUrl
            loader.on 'pageLoaded', (html) =>
                logger.info 'PageLoader finished', pageUrl, html.length
                parser = new PageParser html, @config

                parser.on 'error', (err) ->
                    done err

                parser.on 'metadata', (object) =>
                    logger.info 'Got metadata:', object
                    for key, value of object
                        @feed[key] = value
                        # logger.info @feed[key], value

                parser.on 'item', (item) =>
                    @feed.item item
                    logger.info 'Got item', _.omit item, 'description'
                    articles.push item.url

                parser.on 'end', ->
                    # logger.info @feed
                    loaded += 1
                    if parser.hasNext
                        pageUrl = parser.nextPage
                    done()

                parser.start()

            loader.on 'error', (err) ->
                logger.error "Error while loading page #{pageUrl}", err
                done err

            loader.load @config

        async.until noMoreArticles, loadPage, end
