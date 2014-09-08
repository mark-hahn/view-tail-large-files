
# plugins/sticky-tail

module.exports =
class StickyTail
  
  constructor: (filePath, @view, @reader, @lineMgr) ->

  checkSticky: ->
    if @botLineNum > @lineCount
      if @view.find('.sticky-bar').length is 0
        width = @view.width()
        @view.append '<div class="sticky-bar highlight text-info" ' +
                      'style="width:'  + width + 'px; opacity: 0.3; color:#666; ' +
                             'height:' + @chrH + 'px; background-color:#aaa; ' +
                             'text-align:center">-- Tailing --</div>'
      @lineMgr.setScrollPos @lineCount
    else
      @view.find('.sticky-bar').remove()
  
  newLines: (view, lineNumCharCount, @lineCount, maxLineLen) -> @checkSticky()
  scroll: (view, topLineNum, linesVis, @botLineNum) ->          @checkSticky()
    