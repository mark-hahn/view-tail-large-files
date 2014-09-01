
{View} = require 'atom'

module.exports =
class Line extends View
  
  @content: (widthLine, widthText, top, lineNum, text, lineNumStr) ->
    
    @div class:"line", \
         style: 'position:absolute; color:black;
                 top:'   + top       + 'px;
                 width:' + widthLine + 'px', =>
                    
      @div class:"line-num", \
           style:'clear:both; float:left; margin-right:5px;
                  background-color:#ccc', lineNumStr
      
      @div class:"line-text", \
          "data-line": lineNum, \
           style: 'float:left; width:' + widthText + 'px', text


