EventEmitter = require('events').EventEmitter
url          = require 'url'
cheerio      = require 'cheerio'
moment       = require 'moment'

module.exports = class PageParser extends EventEmitter
    constructor: (@host, @html, @config) ->
        super()
        @$ = cheerio.load @html
        @selectors = @config.selectors
        moment.lang @config.language
    
    start: ->
        date = new Date
        totalItems = 0
        self = this
        $ = this.$
        $(@selectors.item.block).each ->
            $block = $(this)
            item =
                title: $block.find(self.selectors.item.title).text()
                author: $block.find(self.selectors.item.author).text()
                description: $block.find(self.selectors.item.description).html()
                url: url.resolve self.host, $block.find(self.selectors.item.link).attr('href')
                date: moment($block.find(self.selectors.item.pubDate).text() || date - ++totalItems)

            self.emit 'item', item

        @emit 'end'

    Object.defineProperty this.prototype, 'nextPage', 
        get: ->
            element = @$(@selectors.nextPage)
            href = if element.is('a') then element.attr('href')
            else element.find('a').attr('href') || ''

            if url then url.resolve @host, href else null

    Object.defineProperty this.prototype, 'hasNext', 
        get: ->
            @$(@selectors.nextPage).length