
#  line-mgr

fs  = require 'fs-plus'
{$} = require 'atom'
LineView  = require './line-view'
pluginMgr = require './plugin-mgr'

module.exports =
class LineMgr
  
  constructor: (@reader, @fileView, @$lines, @chrW, @chrH) ->
    @lastLineNumCharCount = 0
    @$lineByNum = {}

    @fileView.on 'scroll', => 
      @getScrollPos()
      @loadNearLines()
      @pluginsScroll @topLineNum, @linesVis, @botLineNum
    
    @fileView.on 'click', '.line', -> 
      # console.log '@fileView.on click', $(@).attr 'data-line'
      false
      
  getLinesState:  -> 
    {@view, @lineNumCharCount, @lineCount, @maxLineLen, @chrW, @chrH, }
    
  getScroll: -> 
    @getScrollPos()
    {@view, @topLineNum, @linesVis, @botLineNum}
    
  setPlugins: (plugins, view) ->
    @pluginsNewLines = pluginMgr.getCall plugins, 'newLines', view
    @pluginsScroll   = pluginMgr.getCall plugins, 'scroll', view
  
  appendLine: (lineNum, text) ->
    lineNumStr = '' + lineNum
    if lineNumStr of @$lineByNum then return
    top          = lineNum           * @chrH
    lineNumW     = @lineNumCharCount * @chrW
    lineW        = (@lineNumCharCount + @maxLineLen) * @chrW
    lineView     = new LineView top, lineW, lineNumW, lineNum, text
    @$lines.append lineView
    @$lineByNum[lineNumStr] = lineView
    if (lineNum % 200) is 0 then @removeFarLines()
  
  updateLinesInDOM: ->
    @lineCount  = @reader.getLineCount()
    @maxLineLen = @reader.getMaxLineLen()
    @lineNumCharCount = ('' + @lineCount).length + 2
    if @lastLineNumCharCount isnt @lineNumCharCount
      @fileView.setLineNumsWidth @lineNumCharCount
      @lastLineNumCharCount = @lineNumCharCount
    @fileView.setLinesDivSize @lineNumCharCount, @lineCount, @maxLineLen
    @pluginsNewLines(@lineNumCharCount, @lineCount, @maxLineLen)
    @getScrollPos()
    @loadNearLines()
    
  getScrollPos: ->
    @topLineNum = Math.floor @fileView.scrollTop() / @chrH
    @linesVis   = Math.floor @fileView.height()    / @chrH
    @botLineNum = @topLineNum + @linesVis
    
  loadNearLines: ->
    start = Math.max          0, @topLineNum - 5
    end   = Math.min @lineCount, @botLineNum + 5
    
    lines = @reader.getLines start, end
    for line, idx in lines
      @appendLine start+idx, line
    
  removeFarLines: ->
    @getScrollPos()
    lineNum   = @topLineNum + @linesVis / 2
    lineByNum = @$lineByNum
    deadLines = []
    for num, $line of lineByNum
      if (Math.abs lineNum - num) > 500 then deadLines.push [num, $line]
    for deadLine in deadLines
      delete lineByNum[deadLine[0]]
      deadLine[1].remove()
      
  setScrollPos: (lineNum) -> 
    lineNum = Math.max 0, Math.min @lineCount-1, lineNum
    @fileView.scrollTop lineNum * @chrH
    
  # scrollRelative: (ofs) ->
  #   @getScrollPos()
  #   @scrollToLineNum @topLineNum + ofs
  #   
  # getLineVis: -> @getScrollPos(); @linesVis
        
