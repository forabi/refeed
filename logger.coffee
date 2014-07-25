winston = require('winston')
Logger  = winston.Logger

logger = new Logger
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

winston.addColors colors

module.exports = logger.log.bind logger