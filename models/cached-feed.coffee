_          = require 'lodash'
Feed       = require 'rss'
PageParser = require './page-parser'

module.exports = class CachedFeed extends Feed
    constructor: (xml, config) ->

        config = _.extend config, require('../json/rss.json')
        config.xmlMode = yes

        console.log "CachedFeed config:", config

        parser = new PageParser xml, config
        parser.on 'item', (item) =>
            if not @lastArticleUrl then @lastArticleUrl = item.url
            @item item

        super config
        parser.start()