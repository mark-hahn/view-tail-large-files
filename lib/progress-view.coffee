{View}     = require 'atom'

hdrFontSize = 16
lineCntSize = 14

module.exports =
class ProgressView extends View
  @content: ->
    @div class:'progress editor-colors', \
         style:'margin:30px; width:100%; height:100px; box-shadow:none', =>
      @div class:'intro-hdr', \
           style:'font-size:' + hdrFontSize + 'px; font-weight:bold; margin-bottom:30px'
      @div class:'line-count', \
           style:'clear:both; float:left; font-size:' + lineCntSize + 'px; 
                  width:200px; height:20px', 'Lines Indexed: 0'
      @div class:'progress-bar-outer', \
           style:'position:relative; top:4px; float:left; overflow:hidden;
                  width:200px; height:18px; border:2px solid #888; background-color:#ccc;', =>
        @div class:'progress-bar-inner', \
             style:'position:absolute; left:-200px; top:0; background-color:#444;
                    width:200px; height:20px'
                    
  initialize: (fileSize, @view) ->
    @$progBar    = @find '.progress-bar-inner'
    @$lineCount  = @find '.line-count'
    @find('.intro-hdr').text 'Opening ' + (fileSize / (1024*1024)).toFixed(1) + ' MB ' + 
                             'file for viewing and tailing ...'
    @view.append @

  setProgress: (progress, lineCount) ->
    nowSecs = Math.floor Date.now() / 100
    if @lastSecs is nowSecs then return
    @lastSecs = nowSecs

    @$lineCount.text 'Lines Indexed: ' + Math.floor(lineCount/1024) + 'K'
    @$progBar.css left: -((1 - progress) * 200)
  
  destroy: -> @detach()
