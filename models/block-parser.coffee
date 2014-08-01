log = require "#{process.cwd()}/logger"

EventEmitter = require('events').EventEmitter
url          = require 'url'
# _            = require 'lodash'
chrono       = require 'chrono-node'
moment       = require 'moment'
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
    @option config {Object} selectors see {PageParser#constructor} for details
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
    @throw "NO_SELECTOR"
    ###
    parse: ($block, field, selectorObject) ->
        config = @config

        log 'debug', "Parsing block for #{field}, selector:", selectorObject
        $el = getElement $block, selectorObject

        host = config.host

        switch field
            when 'description'
                mode = if config.xmlMode then 'text' else 'html'
                # log 'debug', "Parsing description in #{mode} mode..."
                try
                    str = ''

                    if $el.length is 1
                        str = $el[mode]()
                    else
                        $el.each ->
                            str += cheerio.load(this)[mode]()

                    if mode is 'html'
                        # Resolve relative links
                        $$ = cheerio.load str
                        $$('a').each ->
                            $this = $$ this
                            href = $this.attr 'href'
                            href = url.resolve host, href
                            $this.attr 'href', href

                        str = $$.html()

                    str.trim() || null
                catch e
                    log 'error', 'Error in parsing article description',
                        e.toString()
                    $el[mode]().trim() || null
            when 'url'
                relative = $el.attr('href') || getContent $el, selectorObject
                try
                    url.resolve host, relative
                catch
                    relative
            when 'date'
                dateString = getContent($el, selectorObject).trim()
                log 'debug', 'Date string is', dateString
                date = new Date dateString
                if not dateString
                    return config.fallbackDate || null
                else if moment(date).isValid()
                    return new Date dateString
                else
                    try
                        chronoDate = chrono.parseDate dateString
                        # Chrono usually parses dates like
                        # Thursday at 12:05 am as being in the future,
                        # we do not want that.
                        if chronoDate < Date.now()
                            return chronoDate
                        else throw new Error 'DATE_PARSE_FAIL'
                    catch e
                        log 'warn', 'DATE_PARSE_FAIL', e
                        date = config.fallbackDate || null
            else # Title, author, image_url...
                getContent $el, selectorObject

    getElement = ($block, selectorObject) ->
        # A selector can be a string, like 'div:not(:first-child)'
        # or an object like { element: '...', method: 'attr', arg: 'date-utime' }
        log 'debug', 'getElement', selectorObject
        # try
        if typeof selectorObject is 'string'
            $block.find selectorObject
        else
            $block.find selectorObject.element
        # catch e
        #     throw new Error 'NO_SELECTOR'

    getContent = ($element, selectorObject) ->
        if not selectorObject
            null
        else if typeof selectorObject is 'string'
            $element.text().trim()
        else $element[selectorObject.method](selectorObject.arg || undefined)