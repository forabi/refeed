HOUR = 3600000

config        = require 'config.js'

fs            = require 'fs'
FeedGenerator = require './models/feed-generator'

updateFeed = ->
    xmlFile = "#{config.dirs.feeds}/feeds/hindawi.xml"
    generator = new FeedGenerator 'hindawi', require './json/hindawi.json', xmlFile
    # generator.maxPages = 3
    generator.on 'end', (xml) ->
        fs.writeFileSync xmlFile, xml
        console.log 'Feed hindawi updated'
    
    generator.generate()

setTimeout ->
    updateFeed()
, 2 * HOUR

updateFeed()