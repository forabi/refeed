var express = require('express');
var app = express();

// Spin up a static server
app.use(express.static(__dirname + '/feeds'));
app.listen(process.env.PORT || 3000);