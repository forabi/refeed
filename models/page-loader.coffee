log = require  "#{process.cwd()}/logger"

EventEmitter = require('events').EventEmitter
request      = require 'request'

###
PageLoader requests a resource located at a given `url` and emits the
response body on success, or an error otherwise.
@event pageloaded - Emitted with the response body (typically HTML) when the resource has been fetched
    @type {String}
@event error - Emitted with an `Error` object on fail
    @type {Error}
###
module.exports = class PageLoader extends EventEmitter
    ###
    @param {String} url The URL of the resource to load
    ###
    constructor: (@url) -> super()

    ###
    Loads the page, listeners for `pageloaded` and `error` should be added before this method is called
    @options {Object} options Additional options for the internal `request` call
    ###
    load: (options = {}) ->
        options.url = @url
        request options, (err, res) =>
            return @emit 'error', err if err
            @emit 'pageloaded', res.body