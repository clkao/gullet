var win
watched-folders = try JSON.parse local-storage.get-item 'watched-folders'
watched-folders ?= {}

# keep runtime info of folders
folders-info = {}
children = []

chooseFile = (name) ->

  chooser = document.querySelector name
  chooser.addEventListener 'change' ->
    if !@value => return
    win.hide!
    watched-folders[@value] = target: 'watch'
    local-storage.set-item 'watched-folders' JSON.stringify watched-folders
    new-watched-folder @value, watched-folders[@value]
    @value = ""

  chooser.click!
  win.focus!

removeWatcher = (dir) ->
  child = folders-info[dir]
  children.splice children.indexOf(child), 1
  folders-info[dir]child?kill!
  
createWatcher = (target, dir) ->
  console.log \1
  exec = require 'child_process' .execFile
  console.log \2
  child = exec 'node_modules/.bin/gulp' <[--require LiveScript ]> ++ target, {cwd: dir}, (error, stdout, stderr) ->
    # XXX: some console feedback
    console.log 'stdout: ' + stdout
    #console.log 'stderr: ' + stderr
    console.log 'exec error: ' + error if error isnt null
  console.log \3
  children.push child
  console.log \4
  folders-info.{}[dir]child = child
  console.log \5

gui = require 'nw.gui'
win = gui.Window.get!

tray = new gui.Tray do
  title: ''
  icon: 'img/icon.png'

tray.menu = menu = new gui.Menu
menu.append <| new gui.MenuItem do
  label: 'Watch...'
.on \click ->
  chooseFile '#fileDialog'
menu.append new gui.MenuItem type: 'separator'

menu.append new gui.MenuItem type: 'separator'
menu.append <| new gui.MenuItem do
  label: 'Quit'
.on \click ->
  for c in children
    c?kill!
  process.exit(0);

function new-watched-folder(dir, {target,stopped}:entry)
  require! path
  base = path.basename dir
  submenu = new gui.Menu
  folder = new gui.MenuItem do
    label: base
    submenu: submenu
    icon: \img/stop.png
  menu.insert folder, 2

  submenu.append <| new gui.MenuItem do
    label: 'Stop'
  .on \click ->
    if @label == \Stop =>
      folder.icon = \img/stop.png
      @label = \Start
      removeWatcher dir
    else => # == \Start
      folder.icon = \img/watch.png
      @label = \Stop
      createWatcher target, dir
    #console.log \TODOSTOP dir

  submenu.append <| target-item = new gui.MenuItem do
    label: "Target: #{target}"
  .on \click ->
    watched-folders[dir].target = target = window.prompt "Build Target for #base", target
    local-storage.set-item 'watched-folders' JSON.stringify watched-folders
    target-item.label = "Target: #{target}"

  submenu.append new gui.MenuItem type: 'separator'
  submenu.append <| new gui.MenuItem do
    label: 'Remove'
  .on \click ->
    delete watched-folders[dir]
    local-storage.set-item 'watched-folders' JSON.stringify watched-folders
    removeWatcher dir
    menu.remove folder

  return if stopped

  folder.icon = \img/watch.png
  createWatcher target, dir

for dir, entry of watched-folders
  new-watched-folder dir, entry
