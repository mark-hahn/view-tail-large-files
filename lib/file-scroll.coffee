
LineView = require './line-view'

class FileScroll
  
  init: (@$lines, @chrH) ->

  appendLine: (lineNum, line) =>
    top          =  lineNum * @chrH
    lineCountStr = '  ' + @lineCount
    lineNumStr   = lineNum + '  '
    for i in [lineNumStr.length..lineCountStr.length] then lineNumStr = ' ' + lineNumStr
    $line = new LineView top, lineNum, lineNumStr, line
    @$lines.append $line
  
  addLines: (lines, @lineCount) ->
      @appendLine @lineCount, lines[0]
  
  scrollUp: ->
  scrollDown: ->
  pageUp: ->
  pageDown: ->
  scrollToTop: ->
  scrollToBottom: ->
  
module.exports = new FileScroll
