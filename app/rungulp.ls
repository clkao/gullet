require! <[liftoff gulp fs]>

handleArguments = (args) ->
  argv = args.argv
  cliPackage = require './package'
  versionFlag = argv.v or argv.version
  tasksFlag = argv.T or argv.tasks
  tasks = argv._
  toRun = if tasks.length then tasks else ['default']
  if versionFlag
    gutil.log 'CLI version', cliPackage.version
    gutil.log 'Local version', args.modulePackage.version if args.localPackage
    process.exit 0
  if not args.modulePath
    gutil.log (gutil.colors.red 'No local gulp install found in'), gutil.colors.magenta args.cwd
    gutil.log gutil.colors.red 'Try running: npm install gulp'
    process.exit 1
  if not args.configPath
    gutil.log gutil.colors.red 'No gulpfile found'
    process.exit 1
  if semver.gt cliPackage.version, args.modulePackage.version
    gutil.log gutil.colors.red 'Warning: gulp version mismatch:'
    gutil.log gutil.colors.red 'Running gulp is', cliPackage.version
    gutil.log gutil.colors.red 'Local gulp (installed in gulpfile dir) is', args.modulePackage.version
  gulpFile = require args.configPath
  gutil.log 'Using gulpfile', gutil.colors.magenta args.configPath
  gulpInst = require args.modulePath
  logEvents gulpInst
  if process.cwd! isnt args.cwd
    process.chdir args.cwd
    gutil.log 'Working directory changed to', gutil.colors.magenta args.cwd
  process.nextTick (->
    return logTasks gulpFile, gulpInst if tasksFlag
    gulpInst.start.apply gulpInst, toRun)

logTasks = (gulpFile, localGulp) ->
  tree = taskTree localGulp.tasks
  tree.label = 'Tasks for ' + gutil.colors.magenta gulpFile

formatError = (e) ->
  return e.message if not e.err
  if e.err.message then return e.err.message
  JSON.stringify e.err

logEvents = (gulpInst) ->
  gulpInst.on 'task_start', (e) -> 
    process.send {running: e.task}
    gutil.log 'Running', '\'' + gutil.colors.cyan e.task + '\'...'
  gulpInst.on 'task_stop', (e) ->
    time = prettyTime e.hrDuration
    gutil.log 'Finished', '\'' + gutil.colors.cyan e.task + '\'', 'in', gutil.colors.magenta time
  gulpInst.on 'task_err', (e) ->
    msg = formatError e
    time = prettyTime e.hrDuration
    gutil.log 'Errored', '\'' + gutil.colors.cyan e.task + '\'', 'in', (gutil.colors.magenta time), gutil.colors.red msg
  gulpInst.on 'task_not_found', (err) ->
    gutil.log gutil.colors.red 'Task \'' + err.task + '\' was not defined in your gulpfile but you tried to run it.'
    gutil.log 'Please check the documentation for proper gulpfile formatting.'
    process.exit 1

gutil = require 'gulp-util'
prettyTime = require 'pretty-hrtime'
semver = require 'semver'
cli = new liftoff name: 'gulp'

cli.on 'require', (name) -> gutil.log 'Requiring external module', gutil.colors.magenta name
cli.on 'requireFail', (name) -> gutil.log (gutil.colors.red 'Failed to load external module'), gutil.colors.magenta name

try require \LiveScript
process.on \message ({dir, target}) ->
  cli.launch (-> handleArguments @), {cwd: dir, _: [target]}
