EventEmitter = require('events').EventEmitter
url          = require 'url'
# _            = require 'lodash'
moment       = require 'moment'

module.exports = class BlockParser
    @parse = (type, $block, config) ->
        selectors = config.selectors
        $el = $block.find selectors.item[type]
        switch type
            when 'title' or 'author'
                $el.text()
            when 'description'
                if config.xmlMode then $el.text() else $el.html()
            when 'url'
                relative = $el.attr('href') || $el.text()
                try
                    url.resolve config.host, relative
                catch
                    relative
            when 'date'
                moment($el.text() || config.fallbackDate).lang(config.language)
