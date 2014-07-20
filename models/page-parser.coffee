EventEmitter = require('events').EventEmitter
url          = require 'url'
cheerio      = require 'cheerio'
moment       = require 'moment'

module.exports = class PageParser extends EventEmitter
    constructor: (@html, @config) ->
        super()
        this.$ = cheerio.load @html, xmlMode: yes
        this.selectors = @config.selectors
        try moment.lang @config.language

    start: ->
        date = new Date
        totalItems = 0
        self = this
        $ = this.$
        console.log self.config.host, 'HOST'
        $(@selectors.item.block).each ->
            $block = $(this)
            item =
                title: try $block.find(self.selectors.item.title).text()
                author: $block.find(self.selectors.item.author).text()
                description: $block.find(self.selectors.item.description).html()
                url: (->
                    el = $block.find(self.selectors.item.link)
                    relative = el.attr('href') || el.text()
                    try
                        url.resolve(self.config.host, relative)
                    catch
                        relative
                )()
                date: moment($block.find(self.selectors.item.date).text() || date - ++totalItems)

            self.emit 'item', item

        @emit 'end'

    Object.defineProperty this.prototype, 'nextPage',
        get: ->
            element = this.$(@selectors.nextPage)
            href = if element.is('a') then element.attr('href')
            else element.find('a').attr('href') || ''

            if url then url.resolve @config.host, href else null

    Object.defineProperty @prototype, 'hasNext',
        get: ->
            this.$(@selectors.nextPage).length