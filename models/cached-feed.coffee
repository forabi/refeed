_          = require 'lodash'
Feed       = require 'rss'
PageParser = require './page-parser'

module.exports = class CachedFeed extends Feed
    lastArticleUrl: null
    constructor: (xml, config) ->

        config = _.defaults require('../json/rss.json'), config
        config.xmlMode = yes
        config.decodeEntities = yes


        parser = new PageParser xml, config
        parser.on 'item', (item) =>
            unless @lastArticleUrl then @lastArticleUrl = item.url
            @item item

        super config
        parser.start()