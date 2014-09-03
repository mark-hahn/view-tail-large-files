
{$} = require 'atom'
LineView = require './line-view'

module.exports =
class FileScroll
  
  constructor: (@reader, @readerView, @$lines, @chrW, @chrH) ->
    @$lineByNum = {}
    @readerView.on 'scroll', => @loadNearLines()
    @readerView.on 'click', '.line', -> 
      console.log '@readerView.on click', $(@).attr 'data-line'
      false
    
    # setTimeout (=> @scrollToBottom()), 2000
    # setTimeout (=> @scrollToTop()   ), 4000

  appendLine: (lineNum, text) ->
    lineNumStr = '' + lineNum
    if lineNumStr of @$lineByNum then return
    top          = lineNum           * @chrH
    lineNumW     = @lineNumCharCount * @chrW
    lineW        = lineNumW + (@maxLineLen * @chrW) + 20
    lineView     = new LineView top, lineW, lineNumW, lineNum, text
    @$lines.append lineView
    @$lineByNum[lineNumStr] = lineView
    if (lineNum % 200) is 0 then @removeFarLines lineNum
  
  addLines: (@lineCount, @lineNumCharCount, @maxLineLen) ->
    @loadNearLines()
    
  getScrollPos: ->
    @topLineNum = Math.floor @readerView.scrollTop() / @chrH
    @linesVis   = Math.floor @readerView.height()    / @chrH
    @botLineNum = @topLineNum + @linesVis
    
  loadNearLines: ->
    @getScrollPos()
    start = Math.max          0, @topLineNum - @linesVis
    end   = Math.min @lineCount, @botLineNum + @linesVis
    
    lines = @reader.getLines start, end
    # console.log start, end, lines.length
    for line, idx in lines
      @appendLine start+idx, line
    
    # minLine = Math.min()
    # maxLine = Math.max()
    # lineByNum = @$lineByNum
    # for num in [start...end]
    #   if ('' + num) not of lineByNum
    #     minLine = Math.min minLine, num
    #     maxLine = Math.max maxLine, num
    # lines = @reader.getLines minLine, maxLine+1
    # console.log minLine, maxLine, lines.length
    # for line, idx in lines
    #   @appendLine minLine+idx, line
  
  removeFarLines: (lineNum) ->
    lineByNum = @$lineByNum
    deadLines= []
    for num, $line of lineByNum
      if (Math.abs lineNum - num) > 500 then deadLines.push [num, $line]
    for deadLine in deadLines
      delete lineByNum[deadLine[0]]
      deadLine[1].remove()
      
  # scrollToLineNum: (lineNum) -> 
  #   lineNum = Math.max 0, Math.min @lineCount-1, lineNum
  #   @readerView.scrollTop lineNum * @chrH
  #   
  # scrollRelative: (ofs) ->
  #   @getScrollPos()
  #   @scrollToLineNum @topLineNum + ofs
  #   
  # getLineVis: -> @getScrollPos(); @linesVis
        
