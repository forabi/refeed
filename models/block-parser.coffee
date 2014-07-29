log = require "#{process.cwd()}/logger"

EventEmitter = require('events').EventEmitter
url          = require 'url'
# _            = require 'lodash'
chrono       = require 'chrono-node'
cheerio      = require 'cheerio'

###
A block parser is responsible for parsing a single field of article fields,
for example a title or description field.

@example
    blockParser = new BlockParser {
        xmlMode: false,
        selectors: {
            title: ...,
            item: {
                block: ...
            }
        }
    }

    item.title = blockParser.parse 'title', $block

###
module.exports = class BlockParser
    ###
    @param {Object} config A configuration object
    @option config {Object} selectors see {FeedGenerator#constructor} for details
    @option config {Boolean} xmlMode
    ###
    constructor: (config) ->
        @config = config

    ###
    @param {String} field name of field to parse
    @param {Object} $block A cheerio object to parse
    @return {String} HTML/Text for field
    @example
        item.title = blockParser.parse 'title', $block
        # Where $block is a cheerio object
    ###
    parse: (field, $block) ->
        config = @config
        selectors = config.selectors
        $el = $block.removeClass().find selectors.item[field]
        switch field
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
                    log 'warn', 'Error parsing date', e
                    config.fallbackDate