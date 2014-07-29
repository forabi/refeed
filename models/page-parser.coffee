log = require  "#{process.cwd()}/logger"

EventEmitter = require('events').EventEmitter
async        = require 'async'
_            = require 'lodash'
url          = require 'url'
cheerio      = require 'cheerio'

BlockParser  = require './block-parser'
PageLoader   = require './page-loader'

###
PagePraser runs an `html` string against a set of rules defined in `config`.
The rules are CSS selectors that define how RSS data is represented in the HTML.
The `config` object also includes some fallback properties.
@event metadata - Emitted when a valid RSS field is found
@event item
@event error
@event pageparsed
@see https://github.com/dylang/node-rss#feedoptions Node RSS documentation for of metadata fields
###
module.exports = class PageParser extends EventEmitter
    ###
    @param {String} html The HTML of the webpage to parse
    @param {Object} config The configuration object
    @option config {String} host The host part of the URL of the page, required for resolving full URLs
    @option config {Date} fallbackDate When a date selector has no matches, or can not be parsed, fallback to this date
    @option config {Object} selectors A map of CSS selectors of elements that correspond to fields in the RSS
    @option config {Boolean} xmlMode Set to `true` if the `html` parameter is XML
    @option config.selectors {String} title
    @option config.selectors {String} description
    @option config.selectors {String} author
    @option config.selectors {Object} item Selectors for a single article
    @option config.selectors.item {String} block Selector for the root of the article
    @option config.selectors.item {String} title (a selector to match on the `block` element)
    @option config.selectors.item {String} author (a selector to match on the `block` element)
    @option config.selectors.item {String} description (a selector to match on the `block` element)
    @option config.selectors.item {String} date (a selector to match on the `block` element)
    @option config.selectors.item {String} url (a selector to match on the `block` element)
    @option config.selectors {String, undefined} full_page If specified, the parser will try to load and extract the full page located at `item.url`
    ###
    constructor: (@html, @config) ->
        super()
        log 'verbose', "PageParser initialized for feed #{@config.title}",
            @config
        @$ = cheerio.load @html, _.pick config, 'xmlMode', 'decodeEntities'
        @selectors = config.selectors

    ###
    Starts parsing the page.
     * Emits `item` on each new article.
     * Emits `metadata` whenever a metadata field is found.
     * Emits `pageparsed` when all articles has been processed.
    ###
    start: ->
        self = this
        $ = @$
        config = @config
        blockParser = new BlockParser @config

        startDate = new Date
        items = []

        for metadata in [
            'title', 'author', 'description', 'url', 'language',
            'categories', 'copyright', 'image_url', 'managingEditor',
            'docs', 'webMaster'
        ]
            matches = $ ":not(#{@selectors.item.block}) #{@selectors[metadata]}"
            if matches.length > 0
                object = new Object
                object[metadata] = matches.text()
                self.emit 'metadata', object


        log 'debug', 'Block selector is', @selectors.item.block
        log 'verbose', "Found #{$(@selectors.item.block).length} items in page"

        $(@selectors.item.block).each ->
            try
                $block = $ this
                item = new Object
                config.fallbackDate = startDate - items.length

                for property in [
                    'title', 'author', 'description', 'url', 'date'
                ]
                    item[property] = blockParser.parse property, $block

                items.push item
                log 'verbose', 'Emitting item', item.url
                self.emit 'item', item unless config.selectors.full_page

            catch err
                log 'error', 'PageParser error', err.message
                self.emit 'error', err

        if config.selectors.full_page
            log 'warn', 'Feed set up to load full articles,
            this may take a while!'

            getFullPage = (item, done) ->
                loader = new PageLoader item.url

                loader.on 'pageloaded', (html) ->
                    log 'info', 'Article page loaded', item.url
                    $$ = cheerio.load html
                    log 'info', 'Article length:', html.length
                    item.description = ($$ config.selectors.full_page).html()
                    done null, item

                loader.on 'error', (err) ->
                    done err

                log 'info', 'Loading article page', item.url
                loader.load config

            async.mapLimit items, 3, getFullPage, (err, items) =>
                return @emit 'error', err if err
                @emit 'item', item for item in items
                @emit 'pageparsed'

        else @emit 'pageparsed'

    ###
    @property {String} nextPage The URL of the next page to load, found using the `nextPage` selector
    ###
    Object.defineProperty @prototype, 'nextPage', {
        get: ->
            href = @$(@selectors.nextPage).attr('href') || ''
            if url then url.resolve @config.host, href else null
    }

    ###
    @property {Boolean} hasNext whether a match for the `nextPage` selector is found
    ###
    Object.defineProperty @prototype, 'hasNext', {
        get: ->
            @$(@selectors.nextPage).length
    }
