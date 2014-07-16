HOUR = 3600000

config        = require './config.js'
defaults      = require './defaults.json'

fs            = require 'fs'
path          = require 'path'
mkdirp        = require 'mkdirp'

FeedGenerator = require './models/feed-generator'

mkdirp.sync feedsDir = path.join config.dirs.root, config.dirs.feeds

updateFeed = ->
    xmlFile = path.join feedsDir, 'hindawi.xml'
    feedConfig = _.defaults require('./json/hindawi.json'), defaults

    generator = new FeedGenerator 'hindawi', feedConfig, xmlFile
    # generator.maxPages = 3
    generator.on 'end', (xml) ->
        fs.writeFileSync xmlFile, xml
        console.log "Feed hindawi written to #{xmlFile}"
    
    generator.generate()

setInterval ->
    updateFeed()
, 2 * HOUR

updateFeed()