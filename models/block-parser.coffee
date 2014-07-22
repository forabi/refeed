EventEmitter = require('events').EventEmitter
url          = require 'url'
# _            = require 'lodash'
chrono       = require 'chrono-node'
cheerio      = require 'cheerio'

module.exports = class BlockParser
    ###
    Class methods use `@method =` synatx, this
    is equivalent to `this.prototype.method =`
    ###
    @parse = (type, $block, config) ->
        selectors = config.selectors
        $el = $block.find selectors.item[type]
        switch type
            when 'title' or 'author'
                $el.text()
            when 'description'
                str = ''
                mode = if config.xmlMode then 'text' else 'html'
                $el.each ->
                    str += cheerio.load(this)[mode]()
                if mode is 'html'
                    # Resolve relative links
                    try
                        $$ = cheerio.load str
                        $$('a').each ->
                                $this = $$ this
                                href = $this.attr 'href'
                                href = url.resolve config.host, href
                                $this.attr 'href', href

                        str = $$.html()
                    catch e
                        console.log 'Error resolving urls in description', e
                str
            when 'url'
                relative = $el.attr('href') || $el.text()
                try
                    url.resolve config.host, relative
                catch
                    relative
            when 'date'
                try
                    chrono.parseDate $el.text()
                catch e
                    console.log 'Error parsing date', e
                    config.fallbackDate