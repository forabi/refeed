expect = require 'expect.js'

fs      = require 'fs'
_       = require 'lodash'
cheerio = require 'cheerio'

BlockParser = require '../models/block-parser'

describe 'BlockParser', ->
    html = '
        <h1>Title</h1>
        <label>Page description</label>
        <div class="article">
            <h2>New Article</h2>
            <p>
                Hello <em>world</em>, again!
            </p>
        </div>
        <div class="article">
            <h2>Old Article</h2>
            <p>
                Hello world!
            </p>
        </div>
    '
    beforeEach ->
        @$html = cheerio.load html
        @blockParser = new BlockParser

    it 'should trim excess whitespaces', ->
        result = @blockParser.parse @$html.root(), 'title', 'h1'
        expect(result).to.be 'Title'

    it 'should parse article description as HTML by default', ->
        result = @blockParser.parse @$html('.article').first(), 'description', 'p'
        expect(result).to.be 'Hello <em>world</em>, again!'

    it 'should support parsing descriptions as plain text', ->
        @blockParser.config = mode: 'text'
        result = @blockParser.parse @$html('.article').first(), 'description', 'p'
        expect(result).to.be 'Hello world, again!'

    it 'should return `null` for fields without matching selectors', ->
        date = @blockParser.parse @$html.root(), 'date', '.date'
        expect(date).to.be null

        url = @blockParser.parse @$html.root(), 'url', '.link'
        expect(url).to.be null

    it 'should throw an error when any argument is missing', ->
        expect(@blockParser.parse).withArgs(@$html.root(), 'date', null).to.throwException()
        expect(@blockParser.parse).withArgs(@$html.root(), null, '.date').to.throwException()
        expect(@blockParser.parse).withArgs(null, 'date', '.date').to.throwException()
