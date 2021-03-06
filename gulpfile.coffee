gulp            = require 'gulp'
gutil           = require 'gulp-util'
_               = require 'lodash'

# fs              = require 'fs'
# exec            = require('child_process').exec
mkdirp          = require 'mkdirp'
path            = require 'path'
async           = require 'async'
# glob            = require 'glob'

# en              = require('lingo').en

plugins = (require 'gulp-load-plugins')()

config = _.defaults gutil.env,
    src:
        root: '.'
        coffee: ['{models,spec}/**/*.coffee', '*.coffee']
        specs: 'spec/*.coffee'
        # specs: 'spec/cached-feed.spec.coffee'

gulp.task 'coffeelint', ->
    gulp.src config.src.coffee, (cwd: config.src.root)
    .pipe plugins.coffeelint()
    .pipe plugins.coffeelint.reporter()

gulp.task 'lint', ['coffeelint']

gulp.task 'test', ->
    gulp.src config.src.specs, (cwd: config.src.root)
    .pipe plugins.mocha
        timeout: 10000
        reporter: 'spec'

gulp.task 'default', ['lint', 'test']