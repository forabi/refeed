var feed = require('./hindawi.json');

var _       = require('lodash'),
    cheerio = require('cheerio'),
    Feed    = require('feed')
    http    = require('http');

var data = '';
var callback = function(res) {
    res.on('data', function(chunk) {
        data += chunk.toString();
        // console.log(chunk);
    });
    res.on('end', function() {
        console.log(data);
    });
};

var req = http.request(feed.home, callback);
req.end();