defaults   = require './defaults.json'

_          = require 'lodash'
fs         = require 'fs'
url        = require 'url'

Feed       = require 'rss'
request    = require 'request'

PageLoader = require './models/page-loader'
PageParser = require './models/page-parser'

json       = require './tmp/hindawi.json'

loader = new PageLoader json.url

loader.on 'pageLoaded', (html) ->
    feed   = new Feed title: json.title, description: json.description, site_url: json.url
    parser = new PageParser json.host, html, json.selectors

    parser.on 'item', (item) ->
        feed.item item

    parser.on 'end', ->
        xml = feed.xml()
        fs.writeFileSync './tmp/hindawi.xml', xml
        process.stdout.write 'Feed should be ready!'

    parser.start()

loader.on 'error', (err) ->
    process.sterr.write err

loader.load _.defaults(json, defaults)