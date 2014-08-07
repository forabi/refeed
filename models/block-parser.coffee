log = require "#{process.cwd()}/logger"

EventEmitter = require('events').EventEmitter
url          = require 'url'
# _            = require 'lodash'
chrono       = require 'chrono-node'
moment       = require 'moment'
cheerio      = require 'cheerio'

###
A block parser is responsible for parsing a single field of article fields,
for example a title or description field. It is also used to parse global
metadata fields.

@example
    blockParser = new BlockParser {
        xmlMode: false
    }

    item.title = blockParser.parse $block, 'title', 'h1'

###
module.exports = class BlockParser
    ###
    @param config {Object} A configuration object
    @option config {Boolean} xmlMode
    @option config {String} mode either 'text' or 'html', if xmlMode is set, this option is ignored
    @option config {String} host If parsing a URL block, specifiy the host part of the feed URL to resolve full article url
    ###
    constructor: (config = { mode: 'html' }) ->
        @config = config

    ###
    @param $block {Object} A cheerio object to parse
    @param field {String} name of field to parse
    @param selectorObject {String, Object} An object or a string describing how to find the field, i.e. `'h1'` or `{ element: 'img', method: 'attr', arg: 'src' }`
    @return {String, Date} HTML/Text/Date for field (Date instance when `field is 'date'`)
    @example
        item.title = blockParser.parse $block, 'title', 'h1'
        # Where $block is a cheerio object
    @throw {Error} `NO_SELECTOR`
    ###
    parse: ($block, field, selectorObject) ->
        throw new Error() if not ($block and field and selectorObject)
        config = @config

        log 'debug', "Parsing block for #{field}, selector:", selectorObject
        $el = getElement $block, selectorObject

        try host = config.host

        switch field
            when 'description'
                mode = if config?.xmlMode then 'text' else config?.mode || 'html'
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
                ar_map = {
                    '٠': '0'
                    '١': '1'
                    '٢': '2'
                    '٣': '3'
                    '٤': '4'
                    '٥': '5'
                    '٦': '6'
                    '٧': '7'
                    '٨': '8'
                    '٩': '9'
                }

                dateString =
                    getContent($el, selectorObject)

                try dateString = dateString.replace /[٠١٢٣٤٥٦٧٨٩]/gi, (c) -> ar_map[c]

                log 'debug', 'Date string is', dateString
                date = new Date dateString
                if not dateString
                    return config?.fallbackDate || null
                else if moment(date).isValid()
                    return new Date dateString
                else if config?.dateFormat and config?.language
                    moment.locale(config.language)
                    momentDate = moment(dateString, config.dateFormat)
                    moment.locale 'en'
                    return momentDate.toDate()
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
                        date = config?.fallbackDate || null
            else # Title, author, image_url...
                getContent $el, selectorObject

    ###
    @private searches `$block` for elements matching `selectorObject`
    @param $block {Object} A cheerio object
    @param selectorObject {String, Object} A selector definition
    @return {Object} A cheerio object
    @throw {Error} `NO_SELECTOR`
    ###
    getElement = ($block, selectorObject) ->
        # A selector can be a string, like 'div:not(:first-child)'
        # or an object like { element: '...', method: 'attr', arg: 'date-utime' }
        log 'debug', 'getElement', selectorObject
        try
            if typeof selectorObject is 'string'
                $block.find selectorObject
            else
                $block.find selectorObject.element
        catch e
            throw new Error 'NO_SELECTOR'

    ###
    @private gets the actual content of an element (could be text, html or an attribute value)
    @param $element {Object} A cheerio object
    @param selectorObject {String, Object} A selector definition
    @return {String, null} the useful content of the `$element` as describe in the selector
    ###
    getContent = ($element, selectorObject) ->
        if not selectorObject
            null
        else if typeof selectorObject is 'string'
            str = $element.first().text().trim()
            str = null if not str.length
            str
        else $element[selectorObject.method](selectorObject.arg || undefined)