winston = require 'winston'

logger = new winston.Logger
    levels:
        debug: 0
        verbose: 1
        info: 2
        warn: 3
        error: 4
    colors: colors =
        debug: 'black'
        verbose: 'gray'
        info: 'blue'
        warn: 'yellow'
        error: 'red'


    transports: [
        new winston.transports.Console level: 'info'
    ]

module.exports = logger.log.bind logger