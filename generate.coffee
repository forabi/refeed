logger = require './logger'

config        = require './config.js'
defaults      = require './defaults.json'

fs            = require 'fs'
_             = require 'lodash'
path          = require 'path'
mkdirp        = require 'mkdirp'

FeedGenerator = require './models/feed-generator'

mkdirp.sync feedsDir = path.join config.dirs.root, config.dirs.feeds

updateFeed = (feedId) ->

    xmlFile = path.join feedsDir, "#{feedId}.xml"

    feedConfig = _.defaults require("./json/#{feedId}.json"), defaults

    generator = new FeedGenerator feedId, feedConfig, xmlFile
    generator.maxPages = config.max_pages_per_feed

    generator.on 'error', (err) ->
        logger.info 'Generator error', err

    generator.on 'end', (xml) ->
        fs.writeFileSync xmlFile, xml
        logger.info "Feed hindawi written to #{xmlFile}"

    generator.generate()

setInterval ->
    updateFeed 'hindawi'
, config.default_interval

updateFeed 'hindawi'