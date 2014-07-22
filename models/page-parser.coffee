logger = require process.cwd() + '/logger'

EventEmitter = require('events').EventEmitter
async        = require 'async'
_            = require 'lodash'
url          = require 'url'
cheerio      = require 'cheerio'

BlockParser  = require './block-parser'
PageLoader   = require './page-loader'

module.exports = class PageParser extends EventEmitter
    constructor: (@html, @config) ->
        super()
        @$ = cheerio.load @html, _.pick @config, 'xmlMode', 'decodeEntities'
        @selectors = @config.selectors

    start: ->
        self = this
        $ = self.$
        config = self.config

        startDate = new Date
        items = []

        $(@selectors.item.block).each ->
            try
                $block = $(this)
                item = new Object
                config.fallbackDate = startDate - items.length

                for property in ['title', 'author', 'description', 'url', 'date']
                    item[property] = BlockParser.parse property, $block, config

                items.push item
                self.emit 'item', item unless config.full_page

            catch err
                logger.info 'PageParser error', err
                self.emit 'error', err

        if config.full_page
            logger.warn 'Feed set up to load full articles, this may take a while!'

            getFullPage = (item, done) ->
                loader = new PageLoader item.url

                loader.on 'pageLoaded', (html) ->
                    logger.info 'Article page loaded', item.url
                    $article = cheerio.load html
                    logger.info 'Article length:', html.length
                    item.description = $article(config.full_page).html()
                    done null, item

                loader.on 'error', (err) ->
                    done err

                logger.info 'Loading article page', item.url
                loader.load config

            async.mapLimit items, 3, getFullPage, (err, items) =>
                return @emit 'error', err if err
                @emit 'item', item for item in items
                @emit 'end'

        else @emit 'end'

    Object.defineProperty this.prototype, 'nextPage',
        get: ->
            href = this.$(@selectors.nextPage).attr('href') || ''
            if url then url.resolve @config.host, href else null

    Object.defineProperty @prototype, 'hasNext',
        get: ->
            this.$(@selectors.nextPage).length