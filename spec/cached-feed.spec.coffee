fs = require 'fs'
_ = require 'lodash'

CachedFeed = require '../models/cached-feed'

describe 'CachedFeed', ->
    xml = fs.readFileSync('./spec/test-files/hindawi.xml').toString()
    beforeEach ->
        @cachedFeed = new CachedFeed xml

    it 'should get the title from the xml', (done) ->
        @cachedFeed.parser.on 'pageparsed', =>
            expect(@cachedFeed.title).toBe 'مؤسسة هنداوي'
            done()

        @cachedFeed.load()


    it 'should sort feeds correctly even without date', (done) ->
        @cachedFeed.parser.on 'pageparsed', =>
            expect(_.first(@cachedFeed.items).title).toBe 'عرائس وشياطين'
            expect(_.last(@cachedFeed.items).title).toBe 'الإسلام وأوضاعنا السياسية'
            done()

        @cachedFeed.load()


    it 'should parse article data correctly', (done) ->
        @cachedFeed.parser.on 'pageparsed', =>
            expect(@cachedFeed.items[0].description).not.toBeNull()
            expect(@cachedFeed.items[0].date).not.toBeDefined()
            expect(@cachedFeed.items[0].author).not.toBeDefined()
            expect(@cachedFeed.items[0].description.length).toEqual(3852)
            expect(@cachedFeed.items[1].description.length).toEqual(3785)
            done()

        @cachedFeed.load()