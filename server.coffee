config = require './config'
log    = require "#{process.cwd()}/logger"

path     = require 'path'
express  = require 'express'
compress = require 'compression'

app = express()

app.use compress()

# Spin up a static server
app.use '/feeds',
    (req, res, next) ->
        res.header 'Content-Type', 'application/rss+xml; charset=UTF-8'
        next()
    express.static(path.join config.dirs.root, config.dirs.feeds)

app.listen config.server.port, config.server.host, ->
    log 'info', "Server listening on
    #{config.server.host}:#{config.server.port}"