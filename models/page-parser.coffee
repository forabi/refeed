log = require  "#{process.cwd()}/logger"

EventEmitter = require('events').EventEmitter
async        = require 'async'
_            = require 'lodash'
url          = require 'url'
cheerio      = require 'cheerio'

BlockParser  = require './block-parser'
PageLoader   = require './page-loader'

###
@event metadata
@see https://github.com/dylang/node-rss#feedoptions for metadata fields
@event item
@event error
@event pageparsed

###
module.exports = class PageParser extends EventEmitter
    ###

    ###
    constructor: (@html, @config) ->
        super()
        log 'verbose', "PageParser initialized for feed #{@config.title}",
            @config
        @$ = cheerio.load @html, _.pick config, 'xmlMode', 'decodeEntities'
        @selectors = config.selectors

    ###

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
                self.emit 'item', item unless config.full_page

            catch err
                log 'error', 'PageParser error', err.message
                self.emit 'error', err

        if config.full_page
            log 'warn', 'Feed set up to load full articles,
            this may take a while!'

            getFullPage = (item, done) ->
                loader = new PageLoader item.url

                loader.on 'pageloaded', (html) ->
                    log 'info', 'Article page loaded', item.url
                    $$ = cheerio.load html
                    log 'info', 'Article length:', html.length
                    item.description = ($$ config.full_page).html()
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
