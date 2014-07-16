HOUR = 3600000

config        = require './config.js'

fs            = require 'fs'
path          = require 'path'
mkdirp        = require 'mkdirp'

FeedGenerator = require './models/feed-generator'

feedsDir = path.join config.dirs.root, 'feeds'
mkdirp.sync feedsDir

updateFeed = ->
    xmlFile = path.join feedsDir, 'hindawi.xml'
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