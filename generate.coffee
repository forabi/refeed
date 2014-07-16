HOUR = 3600000

config        = require './config.js'
defaults      = require './defaults.json'

fs            = require 'fs'
_             = require 'lodash'
path          = require 'path'
mkdirp        = require 'mkdirp'

FeedGenerator = require './models/feed-generator'

mkdirp.sync feedsDir = path.join config.dirs.root, config.dirs.feeds

updateFeed = (feed_id) ->
    xmlFile = path.join feedsDir, "#{feedId}.xml"
    feedConfig = _.defaults require("./json/#{feedId}.json"), defaults

    generator = new FeedGenerator feedId, feedConfig, xmlFile
    # generator.maxPages = 3
    generator.on 'end', (xml) ->
        fs.writeFileSync xmlFile, xml
        console.log "Feed hindawi written to #{xmlFile}"

    generator.generate()

setInterval ->
    updateFeed 'hindawi'
, 2 * HOUR

updateFeed 'hindawi'
