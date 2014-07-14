defaults   = require './defaults.json'

_          = require 'lodash'
fs         = require 'fs'

Feed       = require 'rss'
request    = require 'request'

PageParser = require './models/page-parser'

json       = require './tmp/hindawi.json'

request _.defaults(json, defaults), (err, res) ->
    
    return process.sterr.write err if err;
    
    process.stdout.write 'Got HTML!'
    
    feed   = new Feed title: json.title, description: json.description, site_url: json.url

    parser = new PageParser res.body, json.selectors
    
    parser.on 'item', (item) -> feed.item item

    parser.on 'end', ->
        xml = feed.xml()
        fs.writeFileSync './tmp/hindawi.xml', xml
        process.stdout.write 'Feed should be ready!'

    parser.start()