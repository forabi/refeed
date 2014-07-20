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

module.exports = class FeedGenerator extends EventEmitter
    ###
    @param [String] feedId the unique identifier of the feed to generate
    @param [Object] Feed configuration object
    @param [String] xmlFile Path to an XML file representing a cached version of the feed
    ###
    constructor: (@feedId, @config, cachedXMLPath) ->
        self = this
        feedConfig = _.extend @config, site_url: config.url

        try
            xml = fs.readFileSync(cachedXMLPath).toString()
            @feed = new CachedFeed xml, feedConfig
            console.log "Reusing cached feed file #{cachedXMLPath}"
            console.log "Cached feed XML length is #{xml.length}"
            console.log "Last cached article is #{@feed.lastArticleUrl}"
        catch e
            @feed = new Feed feedConfig
            console.log "Something went wrong while laoding the cached feed,
            was expected at #{cachedXMLPath}", e

    ###
    @property [Number] The maximum number of pages to load, each page instantiates a new PageLoader
    ###
    maxPages: Infinity


    ###
    Generate the feed as XML, emits an `end` event on finish with the XML data
    ###
    generate: ->
        pageUrl        = @config.url
        loaded         = 0
        articles       = []
        parser         = null

        noMoreArticles = =>
            (loaded >= @maxPages) or
            (typeof pageUrl isnt 'string') or
            (_.contains articles, @feed.lastArticleUrl) or
            (!!parser and not parser.hasNext)

        end = =>
            xml = @feed.xml()
            process.stdout.write 'Feed is ready be written!\n'
            @emit 'end', xml

        loadPage = (done) =>
            process.stdout.write "Loading page ##{loaded + 1} (#{pageUrl})\n"

            loader = new PageLoader pageUrl
            loader.on 'pageLoaded', (html) =>
                parser = new PageParser html, @config

                parser.on 'item', (item) =>
                    @feed.item item
                    articles.push item.url

                parser.on 'end', =>
                    loaded += 1
                    if parser.hasNext
                        pageUrl = parser.nextPage
                    done()

                parser.start()

            loader.on 'error', (err) ->
                process.stderr.write err
                done err

            loader.load @config

        async.until noMoreArticles, loadPage, end
