EventEmitter = require('events').EventEmitter

_          = require 'lodash'
async      = require 'async'
fs         = require 'fs'
url        = require 'url'

cheerio    = require 'cheerio'

Feed       = require 'rss'
request    = require 'request'

PageLoader = require './page-loader'
PageParser = require './page-parser'

module.exports = class FeedGenerator extends EventEmitter
    ###
    @param [String] feedId the unique identifier of the feed to generate
    @param [Object] config
    @param [String] xmlFile path to an XML file representing a cached version of the feed
    ###
    constructor: (@feedId, @config, xmlFile) ->
        self = this

        @feed = new Feed
            title: config.title
            description: config.description
            site_url: config.url
            language: config.language

        console.log 'Feed created'

        # Read file if exists, get the last entry guid we fetched
        @cachedFeed =
            path: xmlFile
            $: null
            lastArticleUrl: null

        if @cachedFeed.xmlFile and fs.existsSync @cachedFeed.path
            console.log "Reusing cached feed file #{@cachedFeed.path}"

            xml = fs.readFileSync(@cachedFeed.path).toString()
            console.log "Cached feed XML length is #{xml.length}"

            @cachedFeed.$ = cheerio.load xml, xmlMode: yes
            @cachedFeed.lastArticleUrl = @cachedFeed.$('item').first().find('link').text()

            # Add previously cached items to the feed
            @cachedFeed.$('item').each ->
                self.feed.item(this)

            console.log "Last cached article is #{@cachedFeed.lastArticleUrl}"
        else console.log "Cached file does not exist, was expected at #{@cachedFeed.path}"

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
            (_.contains articles, @cachedFeed.lastArticleUrl) or
            (!!parser and not parser.hasNext)

        end = =>
            xml = @feed.xml()
            process.stdout.write 'Feed is ready be written!\n'
            @emit 'end', xml

        loadPage = (done) =>
            process.stdout.write "Loading page ##{loaded + 1} (#{pageUrl})\n"

            loader = new PageLoader pageUrl
            loader.on 'pageLoaded', (html) =>
                parser = new PageParser @config.host, html, @config

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
