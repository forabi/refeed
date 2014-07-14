var express = require('express');
var app = express();
app.use(express.static(__dirname + '/feeds'));
app.listen(3000);