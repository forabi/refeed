HOUR   = 3600000
path   = require 'path'
_      = require 'lodash'

module.exports = _.defaults (
    server:
        port: process.env.OPENSHIFT_NODEJS_PORT || 8080
        host: process.env.OPENSHIFT_NODEJS_IP || '127.0.0.1'

    dirs:
        root: process.env.OPENSHIFT_DATA_DIR || '.',
        feeds: 'feeds'

    database:
        connection: ''

    generator:
        max_pages_per_feed: 10
        default_interval: HOUR

    logger:
        level: 'debug'

), require './config.default.json'