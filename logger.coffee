winston = require 'winston'

config = require './config'

logger = new winston.Logger
    levels:
        verbose: 0
        debug: 1
        info: 2
        warn: 3
        error: 4
    colors: colors =
        verbose: 'gray'
        debug: 'black'
        info: 'blue'
        warn: 'yellow'
        error: 'red'


    transports: [
        new winston.transports.Console level: config.logger.level
    ]

winston.addColors colors

module.exports = logger.log.bind logger