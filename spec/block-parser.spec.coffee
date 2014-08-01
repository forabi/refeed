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
                Hello world, again!
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
        @html = cheerio.load html
        @blockParser = new BlockParser

    it 'should parse strings as HTML by default', ->
        result = @blockParser.parse @html.root(), 'title', 'h1'
        expect(result).toEqual 'Title'
