log = require './logger'

config        = require './config.js'

fs            = require 'fs'
_             = require 'lodash'
async         = require 'async'
path          = require 'path'
mkdirp        = require 'mkdirp'

FeedGenerator = require './models/feed-generator'

mkdirp.sync feedsDir = path.join config.dirs.root, config.dirs.feeds

feeds =
    fs.readdirSync './json'
    .map (i) -> i.substr 0, i.lastIndexOf '.'

log 'info', "Feed list contains #{feeds.length} items"

startFeed = (feedId) ->
    updateFeed = (feedId) ->
        xmlFile = path.join feedsDir, "#{feedId}.xml"

        feedConfig = require "./json/#{feedId}.json"

        log 'debug', 'Feed configuration:', feedConfig

        generator = new FeedGenerator feedId, feedConfig, xmlFile
        generator.maxPages = config.max_pages_per_feed

        generator.on 'error', (err) ->
            log 'error', 'FeedGenerator error', err

        generator.on 'feedgenerated', (xml) ->
            fs.writeFileSync xmlFile, xml
            log 'info', "Feed #{feedId} written to #{xmlFile}"

            setTimeout ->
                log info "Updating #{feedId}..."
                updateFeed feedId
            , config.default_interval

            log 'info', "Feed scheduled to update in #{config.default_interval}"

        generator.on 'initialized', generator.generate.bind generator

        generator.initialize()


    updateFeed feedId

startFeed feedId for feedId in feeds