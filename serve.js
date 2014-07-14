var express = require('express');
var app = express();

// Spin up a static server
app.use(express.static(__dirname + '/feeds'));
app.listen(3000);

// Start generating feeds and throw them in ./feeds/
require('./index.js')