
{$} = require 'atom'
LineView = require './line-view'

class FileScroll
  
  init: (@reader, @readerView, @$lines, @chrW, @chrH) ->
    @$lineByNum = {}
    @readerView.on 'scroll', (e) => @loadNearLines()

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
    
  loadNearLines: ->
    topLineNum = Math.floor @readerView.scrollTop() / @chrH
    linesVis   = Math.floor @readerView.height()    / @chrH
    botLineNum = topLineNum + linesVis
    start = Math.max          0, topLineNum - linesVis
    end   = Math.min @lineCount, botLineNum + linesVis
    lines = @reader.getLines start, end
    console.log start, end, lines.length
    for line, idx in lines
      @appendLine start+idx, line
      
  removeFarLines: (lineNum) ->
    lineByNum = @$lineByNum
    deadLines= []
    for num, $line of lineByNum
      if (Math.abs lineNum - num) > 500 then deadLines.push [num, $line]
    for deadLine in deadLines
      delete lineByNum[deadLine[0]]
      deadLine[1].remove()
        
  scrollUp: ->
  scrollDown: ->
  pageUp: ->
  pageDown: ->
  scrollToTop: ->
  scrollToBottom: ->
  
module.exports = new FileScroll

