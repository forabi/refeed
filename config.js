var path = require('path');

module.exports = {
    port: process.env.OPENSHIFT_NODEJS_PORT || 8080,
    ip: process.env.OPENSHIFT_NODEJS_IP || '127.0.0.1',
    dirs: {
        root: process.env.OPENSHIFT_DATA_DIR || '.',
        feeds: 'feeds'
    },
    database: {
        connection: ""
    },
   	max_pages_per_feed: Infinity
}