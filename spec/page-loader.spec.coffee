PageLoader = require '../models/page-loader'

describe 'PageLoader', ->
    beforeEach ->
        @loader = new PageLoader
        @config =
            headers:
                'User-Agent': 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:31.0) Gecko/20100101 Firefox/31.0'
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
                'Accept-Language': 'en-US,en;q=0.5'
                'Connection': 'keep-alive'
                'Cache-Control': 'max-age=0'

    it 'should load a gzipped webpage correctly', (done) ->
        @loader.url = 'https://m.facebook.com/'
        @config.gzip = yes

        @loader.on 'pageloaded', (body) ->
            expect(body).toMatch /<html/
            done()

        @loader.on 'error', (err) ->
            throw err
            done()

        @loader.load @config