expect = require 'expect.js'

fs = require 'fs'
_ = require 'lodash'
async = require 'async'

CachedFeed = require '../models/cached-feed'

describe 'CachedFeed', ->
    xml = fs.readFileSync("#{__dirname}/test-files/hindawi.xml").toString()
    xml2 = fs.readFileSync("#{__dirname}/test-files/alomari.xml").toString()

    beforeEach ->
        @cachedFeed = new CachedFeed xml

    it 'should get the title from the xml', (done) ->
        @cachedFeed.on 'ready', =>
            expect(@cachedFeed.title).to.be 'مؤسسة هنداوي'
            done()

        @cachedFeed.load()


    it 'should sort feeds correctly even without date', (done) ->
        @cachedFeed.on 'ready', =>
            expect(_.first(@cachedFeed.items).title).to.be 'عرائس وشياطين'
            expect(_.last(@cachedFeed.items).title)
                .to.be 'الإسلام وأوضاعنا السياسية'
            done()

        @cachedFeed.load()


    it 'should parse article data correctly', (done) ->
        @cachedFeed.on 'ready', =>
            expect(@cachedFeed.items[0].description).not.to.be null
            expect(@cachedFeed.items[0].date).to.be undefined
            expect(@cachedFeed.items[0].author).to.be undefined
            expect(@cachedFeed.items[0].description.length).to.equal 3852
            expect(@cachedFeed.items[1].description.length).to.equal 3785
            done()

        @cachedFeed.load()

    it 'should not mix up titles of two different feeds (weird)', (done) ->
        @cachedFeed2 = new CachedFeed xml2

        async.parallel [
            (done) =>
                @cachedFeed.on 'ready', -> done()
                @cachedFeed.load()

            (done) =>
                @cachedFeed2.on 'ready', -> done()
                @cachedFeed2.load()
        ], (err) =>
            expect(@cachedFeed.title).not.to.equal @cachedFeed2.title
            done()