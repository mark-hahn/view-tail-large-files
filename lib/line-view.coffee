
{View} = require 'atom'

module.exports =
class Line extends View
  
  @content: (top, lineNum, lineNumStr, text) ->
    
    @div class:"line", "data-line": lineNum, \
         style: 'position:absolute; white-space:pre; top:' + top + 'px', =>
                    
      @div class:"line-num", style:'clear:both; float:left; 
                                    margin-right:5px; color:#aaa', lineNumStr
      
      @div class:"line-text", style:'float:left; color:black', text


