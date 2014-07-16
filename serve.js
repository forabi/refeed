var path = require('path');

var config = require('./config.js');
var express = require('express');
var app = express();

// Spin up a static server
app.use('/feeds', express.static(path.join(config.dirs.root, config.dirs.feeds)));

app.listen(config.port, config.ip, function() {
    console.log('Server listening on ' + config.ip + ':' + config.port);
});

require('./generate.js');