
# lib\file-view.coffee

{$, View} = require 'atom'
{Emitter} = require 'event-kit'

module.exports =
class FileView extends View
  
  @content: ->
    @div class:'view-tail-large-files vtlf-form', tabindex:-1, =>
      @div outlet:'vtlf', class:'vtlf-inner', =>
        
        @div outlet:'lines', class:'lines'
            
        @div outlet:'scrollbar', class:'scrollbar', =>
          @div outlet:'thumb', class:'thumb'
              
        @div outlet:'metricsTestDiv', style:'visibility:hidden', =>
          @span outlet:'metricsTestSpan', 'W'
          @div style:"clear:both", '&nbsp'
	             
# API Events
  onDidOpenFile:         (cb) => @fileViewEmitter.on 'did-open-file',          cb
  onDidScroll:           (cb) => @fileViewEmitter.on 'did-scroll',             cb
  onDidGetNewLines:      (cb) => @fileViewEmitter.on 'did-get-new-lines',      cb
  onWillOpenFile:        (cb) => @fileViewEmitter.on 'will-open-file',         cb
  onWillDestroyFileView: (cb) => @fileViewEmitter.on 'will-destroy-file-view', cb

  initialize: (@viewOpener) ->
    @pluginMgr = require './plugin-mgr'
    
# Public API Vars
    @chrW = @chrH = null
    @topLineNum = @linesInView = @botLineNum = @lineCount = 0	 
    @filePath        = @viewOpener.getFilePath()
    @globalEmitter   = @pluginMgr.globalEmitter
    @fileViewEmitter = new Emitter
# End of public vars

    @fileViewEmitter.on 'did-open-file', => @globalEmitter.emit 'did-open-file', @
    
    FileReader = require './file-reader'
    LineMgr    = require './line-mgr'
    @events  = []
    @addEvents()
    
    @pluginMgr.createPlugins @
    
    @okToOpenFile = yes
    @fileViewEmitter.emit 'will-open-file'
    if not @okToOpenFile then @destroy(); return
    
    process.nextTick =>
      ProgressView = require '../lib/progress-view'	
      @reader      = new FileReader @
      progressView = new ProgressView @reader.getFileSize(), @
      @reader.buildIndex progressView, =>
        
        # TODO kludge to fix font problem
        @css fontFamily: 'Courier', fontSize: 14
        
        @chrW = @metricsTestSpan.width()  - 1	    
        @chrH = @metricsTestSpan.height() + 3
        @metricsTestDiv.remove()
        @lineMgr   = new LineMgr    @
        setTimeout =>
          @haveNewLines()
          progressView.destroy()
          @lines.show()
          @focus()
          @fileViewEmitter.emit 'did-open-file'
          
          @resizeSetInterval = setInterval =>
            if @lastArea isnt @width() * @height()
              @resize()
              @lastArea = @width() * @height()
          , 300
        , 500
        
  
  setScroll: (@topLineNum) ->
    if @lineCount <= @linesInView 
      @scrollbar.hide()
      @topLineNum = 0
      @botLineNum = @lineCount-1
    else 
      @topLineNum = Math.max 0, Math.min @lineCount-@linesInView, @topLineNum
      @botLineNum = Math.min @lineCount-1, @topLineNum + @linesInView - 1
      sbHgt       = @scrollbar.height()
      height      = Math.max 16, sbHgt * (@linesInView / @lineCount)
      top         = (sbHgt-height) * (@topLineNum / (@lineCount - @linesInView))
      @thumb.css {top, height}
      @scrollbar.show()
    @lineMgr.updateLinesInDom  @topLineNum, @botLineNum, @lineNumMaxCharCount, @textMaxChrCount
    @fileViewEmitter.emit 'did-scroll'
    
  resize: ->
    @lines.css width: @textMaxChrCount * @chrW
    @linesInView = Math.floor @vtlf.height() / @chrH
    @setScroll @topLineNum
      
  haveNewLines: ->
    oldLineCount = @lineCount
    @lineCount   = @reader.getLineCount()
    @textMaxChrCount  = @reader.getTextMaxChrCount()
    @lineNumMaxCharCount = ('' + @lineCount).length + 2
    @fileViewEmitter.emit 'did-get-new-lines'
    @resize()
    
  keyEvent: (key) ->
    switch key
      when 'up'     then @setScroll (@topLineNum -= 1           )
      when 'down'   then @setScroll (@topLineNum += 1           )
      when 'pgup'   then @setScroll (@topLineNum -= @linesInView)
      when 'pgdown' then @setScroll (@topLineNum += @linesInView)
      when 'top'    then @setScroll (@topLineNum  = 0           )
      when 'bottom' then @setScroll (@topLineNum  = @lineCount  )
    
  mouseEvent: (e) ->
    switch e.type
      when 'mousedown' 
        if e.target is @thumb[0]
          @mouseIsDown   = yes
          @initialMouseY = e.pageY
          @initialThumbY = @thumb.position().top
        else
          pageOfs = (if e.pageY < @thumb.offset().top then -@linesInView else @linesInView)
          @setScroll (@topLineNum += pageOfs)
          @mouseIsPaging = yes
          setTimeout =>
            interval = setInterval =>
              if @mouseIsPaging 
                @setScroll (@topLineNum += pageOfs)
              else
                clearInterval interval
            , 100
          , 250
      when 'mousemove'
        thumbTravel = @height() - @thumb.height() - 20
        mouseDelta  = e.pageY - @initialMouseY
        thumbOfs    = @initialThumbY + mouseDelta
        @setScroll Math.floor (thumbOfs / thumbTravel) * (@lineCount - @linesInView)
      when 'mouseup'
        @mouseIsDown = @mouseIsPaging = no
        
      when 'mousewheel' 
        @setScroll (@topLineNum -= Math.ceil(e.originalEvent.wheelDelta / @chrH))
        
    false
      
  addEvent: ($ele, types, func) ->
    $ele.on types, func
    @events.push [$ele, func]

  addEvents: ->
    @addEvent @, 'view-tail-large-files:up',       => @keyEvent 'up'
    @addEvent @, 'view-tail-large-files:down',     => @keyEvent 'down'
    @addEvent @, 'view-tail-large-files:pgup',     => @keyEvent 'pgup'
    @addEvent @, 'view-tail-large-files:pgdown',   => @keyEvent 'pgdown'
    @addEvent @, 'view-tail-large-files:top',      => @keyEvent 'top'
    @addEvent @, 'view-tail-large-files:bottom',   => @keyEvent 'bottom'

    @addEvent @,          'mousewheel',        (e) => @mouseEvent e
    @addEvent @scrollbar, 'mousedown',         (e) => @mouseEvent e
    @addEvent $(window),  'mousemove mouseup', (e) => 
      if @mouseIsDown or @mouseIsPaging then @mouseEvent e

  destroy: ->
    console.log 'destroy'
    @fileViewEmitter.emit 'will-destroy-file-view'
    if @resizeSetInterval then clearSetInterval @resizeSetInterval
    @reader.destroy()
    @lineMgr.destroy()
    for event of @events then event[0].off event[1]
    @detach()
  
  # detach: ->
    # console.log 'detach'
  