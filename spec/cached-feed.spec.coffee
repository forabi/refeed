fs = require 'fs'
_ = require 'lodash'

CachedFeed = require '../models/cached-feed'

describe 'CachedFeed', ->
    xml = fs.readFileSync('./spec/test-files/hindawi.xml').toString()
    beforeEach ->
        @cachedFeed = new CachedFeed xml, {
            # config
        }

    it 'should parse cached feeds with zero configuration',
    (done) ->
        @cachedFeed.parser.on 'pageparsed', =>
            it 'should get the title from the xml', ->
                expect(@cachedFeed.title).toBe 'مؤسسة هنداوي'

            it 'should sort feeds correctly even without date', ->
                expect(_.first(@cachedFeed.items).title).toBe 'عرائس وشياطين'
                expect(_.last(@cachedFeed.items).title).toBe 'الإسلام وأوضاعنا السياسية'

            it 'should parse article data correctly', ->
                expect(@cachedFeed.items[0].description).not.toBeNull()
                expect(@cachedFeed.items[0].date).not.toBeDefined()
                expect(@cachedFeed.items[0].author).not.toBeDefined()
                expect(@cachedFeed.items[0].description.length).toEqual(3852)
                expect(@cachedFeed.items[1].description.length).toEqual(3758)

            done()

        @cachedFeed.load()