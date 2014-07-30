_ = require 'lodash'

PageParser = require '../models/page-parser'

describe 'PageParser', ->
    beforeEach ->
        @items = []
        @metadata = { }

    it 'should parse an HTML string correctly with minimum configuration',
    (done) ->

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

        config =
            selectors:
                title: 'h1'
                description: 'label'
                item:
                    block: '.article'
                    title: 'h2'
                    description: 'p'

        parser = new PageParser html, config

        expect(parser).toBeDefined()

        parser.on 'error', (err) ->
            throw err

        parser.on 'item', (item) =>
            @items.push item

        parser.on 'metadata', (field) =>
            for key, value of field
                @metadata[key] = value

        parser.on 'pageparsed', =>
            expect(@metadata.title).toBe 'Title'
            expect(@metadata.description).toBe 'Page description'

            expect(@items).toEqual [
                (title: 'New Article', description: 'Hello world, again!')
                (title: 'Old Article', description: 'Hello world!')
            ]

            done()

        parser.start()