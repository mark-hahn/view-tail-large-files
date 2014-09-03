
{View} = require 'atom'

module.exports =
class Line extends View
  
  @content: (top, lineW, lineNumW, lineNum, text) ->
    
    @div class:"line", "data-line": lineNum, \
         style: 'position:absolute; top:' + top + 'px', =>
                    
      @div class:"line-num", \
           style:'clear:both; float:left; text-align:right;
                  width:' + lineNumW + 'px; margin-right:10px; color:#aaa', lineNum + 1
      
      @div class:"line-text", style:'float:left; color:black', text


  destroy: ->
    @detach()

