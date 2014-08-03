fs = require 'fs'
_ = require 'lodash'
async = require 'async'

CachedFeed = require '../models/cached-feed'

describe 'CachedFeed', ->
    xml = fs.readFileSync('./spec/test-files/hindawi.xml').toString()
    xml2 = fs.readFileSync('./spec/test-files/alomari.xml').toString()

    beforeEach ->
        @cachedFeed = new CachedFeed xml

    it 'should get the title from the xml', (done) ->
        @cachedFeed.on 'ready', =>
            expect(@cachedFeed.title).toBe 'مؤسسة هنداوي'
            done()

        @cachedFeed.load()


    it 'should sort feeds correctly even without date', (done) ->
        @cachedFeed.on 'ready', =>
            expect(_.first(@cachedFeed.items).title).toBe 'عرائس وشياطين'
            expect(_.last(@cachedFeed.items).title).toBe 'الإسلام وأوضاعنا السياسية'
            done()

        @cachedFeed.load()


    it 'should parse article data correctly', (done) ->
        @cachedFeed.on 'ready', =>
            expect(@cachedFeed.items[0].description).not.toBeNull()
            expect(@cachedFeed.items[0].date).not.toBeDefined()
            expect(@cachedFeed.items[0].author).not.toBeDefined()
            expect(@cachedFeed.items[0].description.length).toEqual(3852)
            expect(@cachedFeed.items[1].description.length).toEqual(3785)
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
            expect(@cachedFeed.title).not.toEqual(@cachedFeed2.title)
            done()