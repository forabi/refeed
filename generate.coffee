logger = require './logger'

config        = require './config.js'
defaults      = require './defaults.json'

fs            = require 'fs'
_             = require 'lodash'
path          = require 'path'
mkdirp        = require 'mkdirp'

FeedGenerator = require './models/feed-generator'

mkdirp.sync feedsDir = path.join config.dirs.root, config.dirs.feeds

feeds =
    fs.readdirSync('./json')
    .filter (i) -> i isnt 'rss.json'
    .map (i) -> i.substr 0, i.lastIndexOf '.'

logger.info 'Feed list', feeds

startFeed = (feedId) ->
    updateFeed = ->
        xmlFile = path.join feedsDir, "#{feedId}.xml"
        # logger.info 'Got cached file', fs.readFileSync(xmlFile).length

        feedConfig = _.defaults require("./json/#{feedId}.json"), defaults

        logger.info 'feedConfig', feedConfig

        generator = new FeedGenerator feedId, feedConfig, xmlFile
        generator.maxPages = config.max_pages_per_feed

        generator.on 'error', (err) ->
            logger.info 'FeedGenerator error', err

        generator.on 'end', (xml) ->
            # logger.info 'New xml', xml.length
            fs.writeFileSync xmlFile, xml
            logger.info "Feed #{feedId} written to #{xmlFile}"

            setTimeout ->
                logger.info "Updating #{feedId}..."
                updateFeed(feedId)
            , config.default_interval

            logger.info "Feed scheduled to update in #{config.default_interval}"

        generator.generate()

    updateFeed()

startFeed feedId for feedId in feeds