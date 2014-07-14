EventEmitter = require('events').EventEmitter
url          = require 'url'
cheerio      = require 'cheerio'

module.exports = class PageParser extends EventEmitter
    constructor: (@host, @html, @selectors) ->
        super()
    
    start: ->
        self = this
        $ = cheerio.load @html
        $(@selectors.item.block).each ->
            $block = $ @
            item =
                title: $block.find(self.selectors.item.title).text()
                author:
                    name: $block.find(self.selectors.item.author).text()
                description: $block.find(self.selectors.item.description).html()
                url: url.resolve self.host, $block.find(self.selectors.item.link).attr('href')

            self.emit 'item', item

        self.emit 'end'