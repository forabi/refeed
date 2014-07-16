HOUR = 3600000

config        = require './config.js'

fs            = require 'fs'
path          = require 'path'
mkdirp        = require 'mkdirp'

mkdirp.sync config.dirs.feeds

FeedGenerator = require './models/feed-generator'

updateFeed = ->
    xmlFile = path.join config.dirs.feeds, 'feeds/hindawi.xml'
    feedConfig = require './json/hindawi.json'

    generator = new FeedGenerator 'hindawi', feedConfig, xmlFile
    # generator.maxPages = 3
    generator.on 'end', (xml) ->
        fs.writeFileSync xmlFile, xml
        console.log 'Feed hindawi updated'
    
    generator.generate()

setTimeout ->
    updateFeed()
, 2 * HOUR

updateFeed()