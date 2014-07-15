HOUR = 3600000

fs            = require 'fs'
FeedGenerator = require './models/feed-generator'

updateFeed = ->
	generator = new FeedGenerator 'hindawi', require './json/hindawi.json'
	# generator.maxPages = 1
	generator.on 'end', (xml) ->
		fs.writeFileSync './feeds/hindawi.xml', xml
		console.log 'Feed hindawi updated'
	
	generator.generate()

setTimeout ->
	updateFeed()
, 2 * HOUR

updateFeed()