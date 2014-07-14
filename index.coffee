defaults   = require './defaults.json'

_          = require 'lodash'
async      = require 'async'
fs         = require 'fs'
url        = require 'url'

Feed       = require 'rss'
request    = require 'request'

PageLoader = require './models/page-loader'
PageParser = require './models/page-parser'

json       = require './json/hindawi.json'


feed       = new Feed title: json.title, description: json.description, site_url: json.url
pageUrl    = json.url
loaded     = 0
parser     = null
hasNext    = -> loaded < 4 and parser.hasNext and typeof pageUrl is 'string'


writeFile = ->
    xml = feed.xml()
    fs.writeFileSync './feeds/hindawi.xml', xml
    process.stdout.write 'Feed should be ready!\n'

loadPage = (done) ->
    process.stdout.write "Loading page #{pageUrl}\n, total pages loaded: #{loaded}"
    
    loader = new PageLoader pageUrl
    loader.on 'pageLoaded', (html) ->  
        parser = new PageParser json.host, html, json.selectors

        parser.on 'item', (item) ->
            feed.item item

        parser.on 'end', ->
            loaded += 1
            if hasNext
                pageUrl = parser.nextPage
            done()

        parser.start()

    loader.on 'error', (err) ->
        process.stderr.write err
        done err

    loader.load _.defaults(json, defaults)


async.doWhilst loadPage, hasNext, writeFile