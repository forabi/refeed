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
    @option config.selectors {String, Object} title
    @option config.selectors {String, Object} description
    @option config.selectors {String, Object} author
    @option config.selectors {Object} item Selectors for a single article
    @option config.selectors.item {String, Object} block Selector for the root of the article
    @option config.selectors.item {String, Object} title (a selector to match on the `block` element)
    @option config.selectors.item {String, Object} author (a selector to match on the `block` element)
    @option config.selectors.item {String, Object} description (a selector to match on the `block` element)
    @option config.selectors.item {String, Object} date (a selector to match on the `block` element)
    @option config.selectors.item {String, Object} url (a selector to match on the `block` element)
    @option config.selectors {String, undefined} full_page If specified, the parser will try to load and extract the full page located at `item.url`
    ###
    constructor: (@html, @config) ->
        if not @html
            throw new Error 'PageParser must be initialized with HTML/XML
            string as first parameter'

        super()

        @$ = cheerio.load @html, _.pick @config, 'xmlMode', 'decodeEntities'

        if not @config.selectors
            throw new Error 'No selectors were specified
            for PageParser instance'

        @selectors = config.selectors

        log 'verbose', "PageParser initialized for feed #{@config.title}",
            @config

    parseArticle: ($block, fields, selectors) ->
        article = { }
        # config.fallbackDate = startDate - items.length
        for property in fields
            try
                value =
                    @blockParser.parse $block, property, selectors[property]

                article[property] = value if value
            catch e
                log 'error', "Error parsing #{property}:", e.toString()
        return article

    parseMetadataField: ($root, key, selector, done) ->
        @blockParser.parse $root, key, selector

    getFullPage: (article, done) ->
        loader = new PageLoader article.url

        loader.on 'pageloaded', (html) ->
            $$ = cheerio.load html
            article.description = ($$ config.selectors.full_page).html()
            done null, article

        loader.on 'error', (err) ->
            done err

        loader.load config

    ###
    Starts parsing the page.
     * Emits `item` on each new article.
     * Emits `metadata` whenever a metadata field is found.
     * Emits `pageparsed` when all articles has been processed.
    ###
    start: ->
        # self = this
        $root = @$.root()
        @blockParser = new BlockParser @config

        articleSelectors = @selectors.item

        metadataFields   = _.chain(@selectors).pick([
            'title', 'author', 'description', 'url', 'language',
            'categories', 'copyright', 'image_url', 'managingEditor',
            'docs', 'webMaster'
        ]).keys().value()

        articleFields    = _.chain(@selectors.item)
            .omit('block').keys().value()

        articles = $root.find(@selectors.item.block).toArray()

        log 'debug', 'Available metadata fields', metadataFields
        log 'debug', 'Available article fields', articleFields
        log 'debug', 'Block selector is', articleSelectors.block
        log 'debug', "Found #{articles.length} items in page"

        async.waterfall [
            (done) => # Get basic articles
                for article, key in articles
                    try
                        articles[key] =
                            @parseArticle(@$(article),
                                articleFields, articleSelectors)
                    catch err
                        return done err
                done null, articles

            (articles, done) => # Get full pages
                if @config.selectors.full_page
                    log 'warn', 'Feed set up to load full articles,
                    this may take a while!'
                    articles = async.mapSeries articles, @getFullPage, done
                else done null, articles

            (articles, done) => # Emit
                _.map articles, (article) => @emit 'item', article
                done()

        ], (err) =>
            return @emit 'error', err if err

            $root.find(articleSelectors.block).remove()
            for key in metadataFields
                value = @parseMetadataField $root, key, @selectors[key]
                if value
                    object = { }
                    object[key] = value
                    @emit 'metadata', object

            @emit 'pageparsed'


    ###
    @property {String} nextPage The URL of the next page to load, found using the `nextPage` selector
    ###
    Object.defineProperty @prototype, 'nextPage', {
        get: ->
            href = @$(@selectors.nextPage).attr('href') || ''
            host = @config.host
            if url then url.resolve host, href else null
    }

    ###
    @property {Boolean} hasNext whether a match for the `nextPage` selector is found
    ###
    Object.defineProperty @prototype, 'hasNext', {
        get: ->
            @$(@selectors.nextPage).length
    }
