
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
    @div class:'view-tail-large-files vtlf-form', tabindex:-1, =>
      
      @div outlet:'outer', class:'outer', =>
        @div outlet:'lines', class:'lines'
          
      @div outlet:'scrollbar', class:'scrollbar', =>
        @div outlet:'thmbScrl', class:'thmb-scrl', =>
          @div outlet:'thumb', class:'thumb'
	                     
  initialize: (@viewOpener) ->
    super
    pluginMgr  = require './plugin-mgr'
    LineMgr    = require './line-mgr'
    FileReader = require './file-reader'
    @filePath = @viewOpener.getFilePath()
    @reader   = new FileReader @filePath
    @lineMgr  = new LineMgr @reader, @, @lines, chrW, chrH
    @divPixOfs = 0
    
    [@plugins, @pluginsByMethod] = 
      pluginMgr.getPlugins @filePath, @, @reader, @lineMgr, @viewOpener
    @reader.setPlugins  @pluginsByMethod, @
    @lineMgr.setPlugins @pluginsByMethod, @
    @preFileOpen  = pluginMgr.getCall @pluginsByMethod, 'preFileOpen',  @
    @postFileOpen = pluginMgr.getCall @pluginsByMethod, 'postFileOpen', @
  
    @subscribe @scrollbar, 'scroll', @thumbScrlEvent
        	
    process.nextTick =>
      if @preFileOpen(@filePath) is false then @Destroy; return
      ProgressView =  require '../lib/progress-view'
      progressView = new ProgressView @reader.getFileSize(), @
      @reader.buildIndex progressView, =>
        setTimeout => 
          progressView.destroy()
          @lineMgr.updateLinesInDOM()
          @lines.show()
          @focus()
          @postFileOpen @filePath
        , 300
        
    @setThumbPos 0
    
  getFilePath: -> @filePath

  setThumbPos: (lineNum) ->
    @fromSetThumbPos = yes
    @thmbScrl.height (outerH = @height())
    linesH = lineNum * chrH
    if linesH < outerH
      @thumb.height outerH
      @scrollbar.scrollTop 0
    else if @lineCount is 0 
      @thumb.height 16
      @scrollbar.scrollTop 0
    else
      @thumb.height (thumbH = Math.max 16, (outerH / linesH) * outerH)
      @scrollbar.scrollTop (outerH - thumbH) * (1 - (lineNum/(@lineCount-1)))
    @fromSetThumbPos = no
    
  thumbScrlEvent: ->
    if @fromSetThumbPos then return
    lineNum = Math.floor (@lineCount-1) * (1 - (@scrollbar.scrollTop() / (outerH - thumbH)))
    @lineMgr.setScrollPos lineNum, yes

  setLinesDivSize: (lineNumCharCount, @lineCount, 
                    maxLineLen, topLineNum, botLineNum, divHeight) ->
                      
    width = (lineNumCharCount + maxLineLen) * chrW
    @lines.find('.line').css {width}
    @lines.css               {width, height: divHeight+100}

    topPix = topLineNum * chrH - 1000
    botPix = botLineNum * chrH + 1000
    if topPix < @divPixOfs or botPix > @divPixOfs + divHeight
      @divPixOfs = Math.max 0, topPix - divHeight / 2
    @divPixOfs

  destroy: ->
    @viewOpener.getCreator()?.destroy()
    @reader.destroy()
    @lineMgr.destroy()
    for plugin of @plugins then plugin?.destroy()
    @detach()
    @unsubscribe
    
###