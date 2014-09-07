
# lib\file-view.coffee

{$, ScrollView} = require 'atom'
pluginMgr       = require './plugin-mgr'
LineMgr         = require './line-mgr'
FileReader      = require './file-reader'

pluginMgr.activate()

fontFamily  = 'courier'
fontSize    = 14

$testDiv  = $ '<div><span>&nbsp;</span><div style="clear:both">&nbsp;</div></div>'
$testSpan = $testDiv.find 'span'
$testSpan.css {position:'absolute', fontSize, fontFamily, visibility:'hidden'}
$('body').append $testDiv
chrW = $testSpan.width() - 1
chrH = $testDiv.height() + 3
$testDiv.remove()

module.exports =
class FileView extends ScrollView
  
  @content: ->
    @div class:'view-tail-large-files editor-colors', tabindex:-1,  \
         style:'overflow:scroll;', =>
      @div class: 'lines', \
           style:'display:none; white-space:pre; 
                  font-family:' + fontFamily + '; font-size:' + fontSize + 'px'
  
  initialize: (viewOpener) ->
    super
    @$lines   = @find '.lines'
    @filePath = viewOpener.getFilePath()
    reader    = new FileReader @filePath
    @lineMgr  = new LineMgr reader, @, @$lines, chrW, chrH
    
    plugins = pluginMgr.getPlugins @filePath, @, reader, @lineMgr
    reader.setPlugins   plugins, @
    @lineMgr.setPlugins plugins, @
    
    atom.workspaceView.command "pane:item-removed", (e, opener, tabIdx) => 
      if opener is viewOpener 
        # console.log 'pane item closed, destorying reader'
        reader.destroy()
    
  getFilePath: -> @filePath
  get$lines:   -> @$lines

  showLines: -> @$lines.show()
  
  setLineNumsWidth: (lineNumCharCount) ->
    @$lines.find('.line-num').css width: lineNumCharCount * chrW
    
  setLinesContainerSize: (lineNumCharCount, lineCount, maxLineLen) ->
    @$lines.css width:  (lineNumCharCount + maxLineLen) * chrW, \
                height:  lineCount * chrH + 10

  destroy: ->
    @detach()
    @reader?.destroy()
