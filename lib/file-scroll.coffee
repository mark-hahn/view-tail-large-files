
LineView = require './line-view'

class FileScroll
  
  init: (@$lines, @chrW, @chrH) ->

  appendLine: (lineNum, line, maxLineLen) =>
    widthLine  = (maxLineLen + 7) * @chrW
    widthText  =  maxLineLen      * @chrW
    top        =  lineNum         * @chrH
    lineNumStr = lineNum + ':'
    for i in [lineNumStr.length...7] then lineNumStr = ' ' + lineNumStr
    $line = new LineView widthLine, widthText, top, lineNum, line, lineNumStr
    @$lines.append $line
    
  addLines: (lines, @lineCount, @maxLineLen) ->
      @appendLine @lineCount, lines[0]
  
  scrollUp: ->
  scrollDown: ->
  pageUp: ->
  pageDown: ->
  scrollToTop: ->
  scrollToBottom: ->
  
module.exports = new FileScroll
