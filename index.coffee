defaults = require './defaults.json'

_        = require 'lodash'
fs       = require 'fs'
cheerio  = require 'cheerio'
Feed     = require 'rss'
request  = require 'request'

json     = require './hindawi.json'

request _.defaults(json, defaults), (err, res) ->
    
    process.sterr.write err if err;
    
    process.stdout.write 'Got HTML!'
    
    $ = cheerio.load res.body
    feed = new Feed title: json.title, description: json.description, site_url: json.url

    process.stdout.write 'Feed should be ready!'
    

    $(json.selectors.item.block).each ->
        $block = $ @
        item =
            title: $block.find(json.selectors.item.title).text(),
            author:
                name: $block.find(json.selectors.item.author).text()
            description: $block.find(json.selectors.item.description).html(),
            url: $block.find(json.selectors.item.link).attr('href')
        
        feed.item(item);

    xml = feed.xml()
    fs.writeFileSync 'hindawi.xml', xml