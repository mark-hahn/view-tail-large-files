
# lib\file-view.coffee

console.log 'file-view', __dirname, process.cwd()

{$, ScrollView} = require 'atom'

pluginMgr  = null
LineMgr    = null
FileReader = null

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
  
  initialize: (@viewOpener) ->
    super
    pluginMgr  = require './plugin-mgr'
    LineMgr    = require './line-mgr'
    FileReader = require './file-reader'
    # pluginMgr.activate()
    @$lines   = @find '.lines'
    @filePath = @viewOpener.getFilePath()
    @reader    = new FileReader @filePath
    @lineMgr  = new LineMgr @reader, @, @$lines, chrW, chrH
    
    if (Plugin = @viewOpener.getCreatorPlugin()) 
      @creatorPlugin = new Plugin @filePath, @, @reader, @lineMgr, @viewOpener
    
    plugins = pluginMgr.getPlugins @filePath, @, @reader, @lineMgr, @viewOpener
    @reader.setPlugins   plugins, @
    @lineMgr.setPlugins plugins, @
    
    atom.workspaceView.command "pane:item-removed", (e, opener, tabIdx) => 
      if opener is @viewOpener 
        @reader.destroy()
  
  # this is actually just a convenience routine for plugins
  # a view shouldn't be doing things like this.
  # there may be an api.coffee file for this stuff later   
  # this loads a file, shows progress, and finally shows the lines in this view   
  open: ->
    ProgressView = require '../lib/progress-view'
    progressView = new ProgressView @reader.getFileSize(), @
    @reader.buildIndex progressView, =>
      setTimeout => 
        progressView.destroy()
        @lineMgr.updateLinesInDOM()
        @$lines.show()
      , 300
    
  getFilePath: -> @filePath
  get$lines:   -> @$lines

  setLineNumsWidth: (lineNumCharCount) ->
    @$lines.find('.line-num').css width: lineNumCharCount * chrW
    
  setLinesDivSize: (lineNumCharCount, lineCount, maxLineLen) ->
    width  = (lineNumCharCount + maxLineLen) * chrW
    height = lineCount * chrH + 15
    @$lines.find('.line').css {width}
    @$lines.css               {width, height}

  destroy: ->
    @creatorPlugin?.destroy()
    @reader?.destroy()
    @detach()
