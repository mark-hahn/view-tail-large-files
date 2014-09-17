
#  line-mgr

fs  = require 'fs-plus'
{$} = require 'atom'
LineView  = require './line-view'
pluginMgr = require './plugin-mgr'

divHeight = 1e7

module.exports =
class LineMgr
  
  constructor: (@reader, @fileView, @lines, @chrW, @chrH) ->
    @lastLineNumCharCount = 0
    @$lineByNum = {}
    
    @scrollPixOfs = 0

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
    @pluginsScroll   = pluginMgr.getCall plugins, 'scroll',   view
    
  chkLinesDivSize: ->
    @getScrollPos()
    oldOfs    = @scrollPixOfs
    @scrollPixOfs =
      @fileView.setLinesDivSize \
        @lineNumCharCount, @lineCount, @maxLineLen, @topLineNum, @botLineNum, divHeight
    if @scrollPixOfs isnt oldOfs
      delta = @scrollPixOfs - oldOfs
      @lines.find('.line').each ->
        $line  = $ @
        top = $line.position().top + delta
        if (0 <= top < divHeight) then $line.css {top}
        else @deleteLine $line.attr('data-line'), $line
  
  appendLine: (lineNum, text) ->
    lineNumStr = '' + lineNum
    if lineNumStr of @$lineByNum then return
    top = lineNum * @chrH - @scrollPixOfs
    if not (0 <= top < divHeight)
      chkLinesDivSize()
      top = lineNum * @chrH - @scrollPixOfs
    lineNumW = @lineNumCharCount * @chrW
    lineW    = (@lineNumCharCount + @maxLineLen) * @chrW
    lineView = new LineView top, lineW, lineNumW, lineNum, text
    @lines.append lineView
    @$lineByNum[lineNumStr] = lineView
    if (lineNum % 200) is 0 then @removeFarLines()
  
  deleteLine: (lineNum, $line) ->
    delete @$lineByNum[lineNum]
    $line.remove()
    
  updateLinesInDOM: ->
    @lineCount  = @reader.getLineCount()
    @maxLineLen = @reader.getMaxLineLen()
    @lineNumCharCount = ('' + @lineCount).length + 2
    if @lastLineNumCharCount isnt @lineNumCharCount
      @lines.find('.line-num').css width: @lineNumCharCount * @chrW
    @lastLineNumCharCount = @lineNumCharCount
    @chkLinesDivSize()
    @getScrollPos()
    @pluginsNewLines @lineNumCharCount, @lineCount, @maxLineLen, @botLineNum    
    @loadNearLines()
    
  getScrollPos: ->
    scrollTop   = @scrollPixOfs + @fileView.scrollTop()
    height      = @scrollPixOfs + @fileView.height()
    @topLineNum = Math.floor  scrollTop / @chrH
    @linesVis   = Math.floor  height    / @chrH
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
    deadLines = []
    for num, $line of @$lineByNum
      if Math.abs(lineNum - num) > 500 then deadLines.push [num, $line]
    for deadLine in deadLines
      @deleteLine deadLine...
      
  setScrollPos: (lineNum, fromDrag) -> 
    process.nextTick => 
      lineNum = Math.max 0, Math.min @lineCount-1, lineNum
      @lines.parent().scrollTop lineNum * @chrH - @scrollPixOfs
      if not fromDrag then @fileView.setThumbPos lineNum
      
  destroy: ->
        
