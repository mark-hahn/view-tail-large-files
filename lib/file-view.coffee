
# lib\file-view.coffee

{$, View} = require 'atom'

module.exports =
class FileView extends View
  
  @content: ->
    @div class:'view-tail-large-files vtlf-form', tabindex:-1, =>
      @div outlet:'lines', class:'lines'
          
      @div outlet:'scrollbar', class:'scrollbar', =>
        @div outlet:'thumb', class:'thumb'
            
      @div outlet:'metricsTestDiv', style:'visibility:none', =>
        @span outlet:'metricsTestSpan', 'W'
        @div style:"clear:both", '&nbsp'
	                     
  getFilePath: -> @filePath
  
  initialize: (@viewOpener) ->
    # kludge to fix font problem
    @css fontFamily: 'Courier', fontSize: 14
    
    pluginMgr  = require './plugin-mgr'
    LineMgr    = require './line-mgr'
    FileReader = require './file-reader'
    
    @topLineNum = @linesInView = @botLineNum = @lineCount = 0	    
    @filePath = @viewOpener.getFilePath()
    @reader   = new FileReader @filePath
    @events   = []
    @addEvents()
    
    [@plugins, @pluginsByMethod] = 
      pluginMgr.getPlugins @filePath, @, @reader, @viewOpener
    @reader.setPlugins  @pluginsByMethod, @
    @postFileOpen    = pluginMgr.getCall @pluginsByMethod, 'postFileOpen', @
    @lineApprove     = pluginMgr.getCall @pluginsByMethod, 'lineApprove',  @
    @lineDisplay     = pluginMgr.getCall @pluginsByMethod, 'lineDisplay',  @
    @pluginsNewLines = pluginMgr.getCall @pluginsByMethod, 'newLines',     @
    @pluginsScroll   = pluginMgr.getCall @pluginsByMethod, 'scroll',       @
    
    process.nextTick =>
      ProgressView = require '../lib/progress-view'	
      progressView = new ProgressView @reader.getFileSize(), @
      @reader.buildIndex progressView, =>
        if not @haveMetrics
          @chrW = @metricsTestSpan.width()  - 1
          @chrH = @metricsTestSpan.height() + 3
          @metricsTestDiv.remove()
          @haveMetrics = yes
        @lineMgr = new LineMgr @lines, @reader, @chrW, @chrH
        setTimeout => 
          @haveNewLines()
          progressView.destroy()
          @lines.show()
          @focus()
          @postFileOpen @filePath
          @resizeSetInterval = setInterval =>
            if @lastArea isnt @width() * @height()
              @resize()
              @lastArea = @width() * @height()
          , 300
        , 300
    
  setScroll: (@topLineNum) ->
    @topLineNum = Math.min @topLineNum, @lineCount - @linesInView
    console.assert @botLineNum < @lineCount - 1, {@topLineNum, @botLineNum, @lineCount, @linesInView}
    @botLineNum = @topLineNum + @linesInView - 1
    if @lineCount <= @linesInView then @scrollbar.hide()
    else 
      viewH = @height()
      linesH = @lineCount * @chrH
      @scrollbar.show()
      @thumb.css
        top:     (viewH - 16) * (@topLineNum / (@lineCount - @linesInView))
        height:  (thumbH = Math.max 16, (viewH / linesH) * viewH)
    @lineMgr.updateLinesInDom @topLineNum, @botLineNum, @lineNumCharCount, @maxLineLen
    @pluginsScroll @topLineNum, @botLineNum, @lineNumCharCount, @maxLineLen
    
  resize: ->
    @lines.css width: @width() - 18
    @linesInView = Math.floor(@height() / @chrH) - 1
    @setScroll @topLineNum
      
  haveNewLines: ->
    @lineCount = @reader.getLineCount()
    @maxLineLen = @reader.getMaxLineLen()
    @lineNumCharCount = ('' + @lineCount).length + 2
    @pluginsNewLines @lineNumCharCount, @lineCount, @maxLineLen, @topLineNum, @botLineNum
    @resize()
    
  scrollFromMouse: (e) ->
    thumbTravel = @height() - 36
    mouseOfs    = e.pageY - @offset().top
    thumbOfs    = Math.max 0, Math.min thumbTravel, mouseOfs - 8
    @setScroll Math.floor (thumbOfs / thumbTravel) * (@lineCount - @linesInView)
    
  mouseEvent: (e) ->
    switch e.type
      when 'mousedown' then    @mouseIsDown = yes; @scrollFromMouse e
      when 'mouseup'   then    @mouseIsDown = no
      when 'mousemove' then if @mouseIsDown then   @scrollFromMouse e
    false
      
  addEvent: ($ele, types, func) ->
    $ele.on types, func
    @events.push [$ele, func]

  addEvents: ->
    @addEvent @scrollbar, 'mousedown',                   (e) => @mouseEvent e
    @addEvent $(window),  'mouseup mousemove',           (e) => @mouseEvent e

  destroy: ->
    if @resizeSetInterval then clearSetInterval @resizeSetInterval
    @viewOpener.getCreator()?.destroy()
    @reader.destroy()
    @lineMgr.destroy()
    for plugin of @plugins then plugin?.destroy()
    for event  of @events  then event[0].off event[1]
    @detach()
    