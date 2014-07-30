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
        specs: 'spec/*.coffee'

gulp.task 'default', -> null

gulp.task 'test', ->
    gulp.src config.src.specs, cwd: config.src.root
    .pipe plugins.jasmine timeout: 10000