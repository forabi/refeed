var _       = require('lodash'),
    fs      = require('fs'),
    cheerio = require('cheerio'),
    Feed    = require('rss')
    request = require('request');

var json = require('./hindawi.json');

request(_.defaults(json, {
    gzip: true,
    headers: {
        "User-Agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.5",
        "Connection": "keep-alive",
        "Cache-Control": "max-age=0"
    }
}), function(err, res) {
    if (err) throw err;
    console.log('Got HTML!');
    $ = cheerio.load(res.body);
    
    var feed = new Feed({
        title: json.title,
        description: json.description || '',
        site_url: json.home
    });

    $(json.selectors.item.block).each(function() {
        $block = $(this);
        // console.log($block).text();
        item = {
            title: $block.find(json.selectors.item.title).text(),
            author: {
                name: $block.find(json.selectors.item.author).text()
            },
            description: $block.find(json.selectors.item.description).html(),
            url: $block.find(json.selectors.item.link).attr('href')
        };
        feed.item(item);
    });

    console.log('Feed should be ready!');
    
    xml = feed.xml();
    fs.writeFileSync('hindawi.xml', xml);
});