
# lib\file-view.coffee

{$, View} = require 'atom'
{Emitter} = require 'event-kit'

module.exports =
class FileView extends View
  
  @content: ->
    @div class:'view-tail-large-files vtlf-form', tabindex:-1, =>
      @div outlet:'vtlfHoriz', class:'vtlf-horiz', =>
        @div outlet:'linesOuter', class:'lines-outer editor-colors', =>
          @div outlet:'lines', class:'lines'
        @div outlet:'scrollbar', class:'scrollbar', =>
          @div outlet:'thumb', class:'thumb'
            
      @div outlet:'metricsTestDiv', style:'visibility:hidden', =>
        @span outlet:'metricsTestSpan', 'W'
        @div style:"clear:both", '&nbsp'
	             
# API Events
  onWillOpenFile:        (cb) => @fileViewEmitter.on 'will-open-file',         cb
  onDidOpenFile:         (cb) => @fileViewEmitter.on 'did-open-file',          cb
  onDidGetNewLines:      (cb) => @fileViewEmitter.on 'did-get-new-lines',      cb
  onWillScroll:          (cb) => @fileViewEmitter.on 'will-scroll',            cb
  onDidScroll:           (cb) => @fileViewEmitter.on 'did-scroll',             cb
  onWillDestroyFileView: (cb) => @fileViewEmitter.on 'will-destroy-file-view', cb

  initialize: (@viewer) ->
    @pluginMgr = require './plugin-mgr'
    
# Public API Vars
    @chrW = @chrH = null
    @topLineNum = @linesInView = @botLineNum = @lineCount = 0	 
    @filePath        = @viewer.getPath()
    @globalEmitter   = @pluginMgr.globalEmitter
    @fileViewEmitter = new Emitter
# End of public vars

    @fileViewEmitter.on 'did-open-file', => @globalEmitter.emit 'did-open-file', @
    
    FileReader = require './file-reader'
    LineMgr    = require './line-mgr'
    @events  = []
    @addEvents()
    
    @plugins = @pluginMgr.createPlugins @
    
    @okToOpenFile = yes
    @fileViewEmitter.emit 'will-open-file'
    if not @okToOpenFile then @destroy(); return
    
    process.nextTick =>
      ProgressView = require '../lib/progress-view'	
      @reader      = new FileReader @
      progressView = new ProgressView @reader.getFileSize(), @
      @reader.buildIndex progressView, =>
        fontFamily = atom.config.get 'view-tail-large-files.fontFamily'
        fontSize   = atom.config.get 'view-tail-large-files.fontSize'
        @metricsTestSpan.css {fontFamily, fontSize} 
        @chrW = @metricsTestSpan.width()
        @chrH = @metricsTestSpan.height() + 3
        @metricsTestDiv.remove()
        
        @lineMgr = new LineMgr    @
        setTimeout =>
          @haveNewLines()
          progressView.destroy()
          @css {fontFamily, fontSize} 
          @lines.css display: 'inline-block'
          @focus()
          @fileViewEmitter.emit 'did-open-file'
          
          @resizeSetInterval = setInterval =>
            w = @vtlfHoriz.width()
            h = @vtlfHoriz.height()
            if @lastArea isnt w * h
              @resize()
              @lastArea = w * h
          , 300
        , 500
        
    atom.workspaceView.command "pane:item-removed", (e, item) =>
      if item is @viewer then @destroy()
  
  setScroll: (@topLineNum) ->
    @fileViewEmitter.emit 'will-scroll'
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
    
  setScrollRelative: (ofs) -> @setScroll @topLineNum + ofs
    
  resize: ->
    @lines.css width: (@lineNumMaxCharCount + @textMaxChrCount) * @chrW + 50
    @linesInView = Math.floor (@vtlfHoriz.height()-16) / @chrH	     
    @setScroll @topLineNum
      
  haveNewLines: ->
    oldLineCount         = @lineCount
    @lineCount           = @reader.getLineCount()
    @textMaxChrCount     = @reader.getTextMaxChrCount()
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
            @pagingInterval = setInterval =>
              if @mouseIsPaging then @setScroll (@topLineNum += pageOfs)
              else clearInterval @pagingInterval; @pagingInterval = null
            , 100
          , 250
      when 'mousemove'
        if not @mouseIsDown or e.which is 0 then @mouseIsDown = no; return
        thumbTravel = @height() - @thumb.height() - 20
        mouseDelta  = e.pageY - @initialMouseY
        thumbOfs    = @initialThumbY + mouseDelta
        @setScroll Math.floor (thumbOfs / thumbTravel) * (@lineCount - @linesInView)
      when 'mouseup'
        @mouseIsDown = @mouseIsPaging = no
        
      when 'mousewheel' 
        @setScroll (@topLineNum -= Math.ceil(e.originalEvent.wheelDelta / @chrH))
        
  addEvent: ($ele, types, func) ->
    $ele.on types, func
    @events.push [$ele, types, func]

  addEvents: ->
    @addEvent @, 'view-tail-large-files:up',       => @keyEvent 'up'
    @addEvent @, 'view-tail-large-files:down',     => @keyEvent 'down'
    @addEvent @, 'view-tail-large-files:pgup',     => @keyEvent 'pgup'
    @addEvent @, 'view-tail-large-files:pgdown',   => @keyEvent 'pgdown'
    @addEvent @, 'view-tail-large-files:top',      => @keyEvent 'top'
    @addEvent @, 'view-tail-large-files:bottom',   => @keyEvent 'bottom'

    @addEvent @,          'mousewheel',        (e) => @mouseEvent e
    @addEvent @scrollbar, 'mousedown mouseup', (e) => @mouseEvent e
    @addEvent $(window),  'mousemove mouseup', (e) => @mouseEvent e

  destroy: ->
    @detach()
    @fileViewEmitter.emit 'will-destroy-file-view'
    for event  in @events  then event[0].off event[1], event[2]
    for plugin in @plugins then plugin?.destroy?()
    if @resizeSetInterval  then clearInterval @resizeSetInterval
    if @pagingInterval     then clearInterval @pagingInterval
    @reader?.destroy()
    @lineMgr?.destroy()
  