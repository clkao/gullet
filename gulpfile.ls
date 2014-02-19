require! <[gulp gulp-livescript gulp-jade gulp-exec]>
require('gulp-grunt') gulp

gutil = require 'gulp-util'

gulp.task 'js:livescript' ->
  gulp.src 'app/**/*.ls'
    .pipe gulp-livescript({+bare}).on 'error', gutil.log
    .on \error -> throw it
    .pipe gulp.dest './_public/'

gulp.task 'html:jade' ->
  gulp.src 'app/**/*.jade'
    .pipe gulp-jade!
    .pipe gulp.dest './_public/'

gulp.task 'asset' ->
  gulp.src 'app/asset/**/*'
    .pipe gulp.dest './_public/'

gulp.task 'app:asset' <[asset html:jade js:livescript]> (done) ->
  gulp.src '_public/package.json'
    .pipe gulp-exec 'cd _public && npm i'
    .on \error ->
      throw it

gulp.task 'default' <[app:asset]>
