
# lib/line-mgr.coffee

$ = require 'jquery'

module.exports =
class LineMgr
  
  constructor: (@fileView) ->
    {@lines, @reader, @chrW, @chrH} = @fileView
    @subs = []
    @topLineNumInDom = @botLineNumInDom = -1
    @setEvents()
    
  appendLine: (lineNum, text) ->
    top      = (lineNum - @topLineNum) * @chrH 
    lineNumW = @lineNumMaxCharCount    * @chrW
    lineW    = (@lineNumMaxCharCount + @textMaxChrCount) * @chrW + 50
    $line = $ """
      <div class="line", data-line="#{lineNum}" style="top:#{top}px; width:#{lineW}px">
        <div class="line-num" style="width:#{lineNumW}px">#{lineNum+1}</div>
        <div class="line-text" style="left:#{lineNumW+30}px"></div>
      </div>
    """
    $line.find('.line-text').text text
    @lines.append $line
    
  updateLinesInDom: (@topLineNum, @botLineNum, @lineNumMaxCharCount, @textMaxChrCount) ->
    
    if @topLineNum > @botLineNumInDom or @botLineNum < @topLineNumInDom
      @lines.empty()
      lines = @reader.getLines @topLineNum, @botLineNum+1
      for line, idx in lines then @appendLine @topLineNum + idx, line
        
    else 
      if @topLineNumInDom < @topLineNum
        for lineNum in [@topLineNumInDom...@topLineNum]
          @lines.find('.line[data-line=' + lineNum + ']').remove()
        
      if @botLineNum < @botLineNumInDom
        for lineNum in [@botLineNum+1..@botLineNumInDom]
          @lines.find('.line[data-line=' + lineNum + ']').remove()

      if @topLineNum < @topLineNumInDom
        lines = @reader.getLines @topLineNum, @topLineNumInDom
        for line, idx in lines then @appendLine @topLineNum + idx, line

      if @botLineNumInDom < @botLineNum
        lines = @reader.getLines @botLineNumInDom+1, @botLineNum+1
        for line, idx in lines then @appendLine @botLineNumInDom + idx+1, line
          
      if @topLineNum isnt @topLineNumInDom and
          (overlapTop = Math.max(@topLineNumInDom, @topLineNum)) <=
          (overlapBot = Math.min(@botLineNumInDom, @botLineNum))
        for lineNum in [overlapTop..overlapBot]
          @lines.find('.line[data-line=' + lineNum + ']')
                .css top: (lineNum - @topLineNum) * @chrH 
        
    if @lastlineNumMaxCharCount isnt @lineNumMaxCharCount
      @lines.find('.line-num').css width: @lineNumMaxCharCount * @chrW
    @lastlineNumMaxCharCount = @lineNumMaxCharCount

    @topLineNumInDom = @topLineNum
    @botLineNumInDom = @botLineNum
    
  clearSelection: -> @fileView.find('.line').removeClass 'line-selected'
  
  startSelecting: (e) ->
    @selecting = yes
    @selectOrigin = +$(e.target).closest('.line').attr 'data-line'
    @extendSelection e
    
  extendSelection: (e) ->
    if not @selectOrigin? then return
    $line   = $(e.target).closest '.line'
    lineNum = +$line.attr 'data-line'
    if lineNum < @selectOrigin
      startLine = lineNum
      endLine   = @selectOrigin
    else
      startLine = @selectOrigin
      endLine   = lineNum
    @clearSelection()
    @fileView.find('.line').each (idx, ele) =>
      $line = $ ele
      if startLine <= +$line.attr('data-line') <= endLine
        $line.addClass 'line-selected'
    @copy()
        
  mouseDown: (e) ->
    @mouseIsDown = yes
    if e.shiftKey then @extendSelection e
    else @clearSelection()
    false
  
  mouseMove: (e) ->
    if @mouseIsDown
      if not @selecting then @startSelecting e
      else @extendSelection e
    false

  mouseUp: ->
    @selecting = @mouseIsDown  = no
    
  copy: ->
    textArr = []
    @fileView.find('.line-selected').each (idx, ele) =>
      $line = $ ele
      lineNum = +$line.attr 'data-line'
      textArr.push [lineNum, $line.find('.line-text').text()]
    if textArr.length is 0 then return
    textArr.sort()
    txt = ''
    for line in textArr then txt += line[1]
    atom.clipboard.write txt
    
  setEvents: ->
    @subs.push @fileView.on 'mousedown', '.line', (e) => @mouseDown e
    @subs.push @fileView.on 'mousemove', '.line', (e) => @mouseMove e
    @subs.push @fileView.on 'mouseup',   '.line',     => @mouseUp()

  destroy: ->
    for sub in @subs then sub.off()
