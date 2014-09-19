
# lib/line-mgr.coffee

{$} = require 'atom'

module.exports =
class LineMgr
  
  constructor: (@lines, @reader, @chrW, @chrH) ->	  
    @topLineNumInDom = @botLineNumInDom = -1
    
  appendLine: (lineNum, text) ->
    top = (lineNum - @topLineNum) * @chrH 
    lineNumW = @lineNumCharCount  * @chrW
    lineW    = (@lineNumCharCount + @maxLineLen) * @chrW
    $line = $ """
      <div class="line", data-line="#{lineNum}" style="top:#{top}px; width:#{lineW}">
        <div class="line-num" style="width:#{lineNumW}px">#{lineNum+1}</div>
        <div class="line-text"></div>
      </div>
    """
    $line.find('.line-text').text text
    @lines.append $line
    
  updateLinesInDom: (@topLineNum, @botLineNum, @lineNumCharCount, @maxLineLen) ->
    
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
        
    if @lastLineNumCharCount isnt @lineNumCharCount
      @lines.find('.line-num').css width: @lineNumCharCount * @chrW
    @lastLineNumCharCount = @lineNumCharCount

    @topLineNumInDom = @topLineNum
    @botLineNumInDom = @botLineNum

