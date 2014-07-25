log = require './logger'

config        = require './config.js'

fs            = require 'fs'
_             = require 'lodash'
path          = require 'path'
mkdirp        = require 'mkdirp'

FeedGenerator = require './models/feed-generator'

mkdirp.sync feedsDir = path.join config.dirs.root, config.dirs.feeds

feeds =
    fs.readdirSync './json'
    .map (i) -> i.substr 0, i.lastIndexOf '.'

log 'info', "Feed list contains #{feeds.length} items"

startFeed = (feedId) ->
    updateFeed = ->
        xmlFile = path.join feedsDir, "#{feedId}.xml"
        log 'debug', 'Got cached file', fs.readFileSync(xmlFile).length

        feedConfig = require "./json/#{feedId}.json"

        log 'debug', 'Feed configuration:', feedConfig

        generator = new FeedGenerator feedId, feedConfig, xmlFile
        generator.maxPages = config.max_pages_per_feed

        generator.on 'error', (err) ->
            log 'error', 'FeedGenerator error', err

        generator.on 'end', (xml) ->
            fs.writeFileSync xmlFile, xml
            log 'info', "Feed #{feedId} written to #{xmlFile}"

            setTimeout ->
                log info "Updating #{feedId}..."
                updateFeed(feedId)
            , config.default_interval

            log 'info', "Feed scheduled to update in #{config.default_interval}"

        generator.generate()

    updateFeed()

startFeed feedId for feedId in feeds