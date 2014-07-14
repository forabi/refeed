EventEmitter = require('events').EventEmitter
request      = require 'request'

module.exports = class PageLoader extends EventEmitter   
    constructor: (@url) -> super()
    load: (options) ->
        options.url = @url
        request options, (err, res) =>
            return @emit 'error', err if err
            @emit 'pageLoaded', res.body