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
        $el = $block.removeClass().find selectors.item[type]
        switch type
            when 'title' or 'author'
                $el.text()
            when 'description'
                mode = if config.xmlMode then 'text' else 'html'
                try
                    str = ''

                    if $el.length is 1
                        str = $el[mode]()
                    else
                        $el.each ->
                            str += cheerio.load(this)[mode]()

                    # console.log 'str:', str

                    if mode is 'html'
                        # Resolve relative links
                        $$ = cheerio.load str
                        $$('a').each ->
                            $this = $$ this
                            href = $this.attr 'href'
                            href = url.resolve config.host, href
                            $this.attr 'href', href

                        str = $$.html()

                    str
                catch e
                    console.log 'Error in parsing article description', e
                    $el[mode]()
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