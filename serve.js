var config = require('./config.js');
var express = require('express');
var app = express();

// Spin up a static server
app.use(express.static(config.dirs.feeds + '/feeds'));
app.listen(config.port || 8080);

require('./generate.js');