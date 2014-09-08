
# plugins/file-picker

fs     = require 'fs-plus'
{$, View} = require 'atom'

class FilePickerView extends View
  
  @content: ->
    @div class:'vtlf-file-picker overlay from-top', \
         style: 'position:absolute; tabindex: -1; margin:0', =>
  
  initialize: ->
    wsv = atom.workspaceView
    ww     = wsv.width()
    wh     = wsv.height()
    width  = 600
    height = wh - 200
    left   = (ww - width)/2
    top    = 80
    @css {left, top, width, height}
    console.log 'initialize',  {ww, wh, left, top, width, height}
    wsv.append @
    
    @click => @destroy()
      
  destroy: -> @detach()

module.exports =
class FilePicker
  
  @activate = ->
    ViewOpener = require '../lib/view-opener'
    
    atom.workspaceView.command "view-tail-large-files:open", ->
      new FilePickerView
      
  #     filePath = 'c:\\apps\\insteon\\data\\hvac.log'
  #     atom.workspace.activePane.activateItem new ViewOpener filePath, @
  
  # constructor: (filePath, view, reader, lineMgr, viewOpener) ->
  #   view.open()
  

  