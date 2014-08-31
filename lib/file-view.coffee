
# lib\file-view.coffee

{ScrollView} = require 'atom'

module.exports =
class FileReaderView extends ScrollView
  
  @content: ->
    @div =>
      @div class:'intro', style:'margin:30px; width:100%; height:100px', =>
        @div class:'intro-hdr', style:'font-size:20px; font-weight:bold; margin-bottom:30px'
        @div class:'line-count', \
             style:'clear:both; float:left; font-size:18px; color:black; 
                    width:200px; height:20px', 'Lines Indexed: 0'
        @div class:'progress-bar-outer', \
             style:'position:relative; top:4px; float:left; overflow:hidden;
                    width:200px; height:18px; border:2px solid black', =>
          @div class:'progress-bar-inner', \
               style:'position:absolute; left:-200px; top:0;
                      width:200px; height:20px; background-color:green'
      @div class:'outer-scroll-div',  \
           style:'display:none; background-color:white; width:100%; height:1000px'
    
  initialize: (@reader) ->
    super
    $intro     = @find '.intro'
    $introHdr  = @find '.intro-hdr'
    $progBar   = @find '.progress-bar-inner'
    $lineCount = @find '.line-count'
    $scroll    = @find '.outer-scroll-div'
    
    $introHdr.text 'Opening large file (' +  @reader.getSize() + ') as read-only ...'
    
    @reader.readAndIndex (progress, lineCount) ->
      if lineCount > 1024
        $lineCount.text 'Lines Indexed: ' + Math.floor(lineCount/1024) + 'K'
      $progBar.css left: -((1 - progress) * 200)
      # if progress is 1
      #   $intro.hide()
      #   $scroll.show()
  
  afterAttach: (onDom) -> 
    if not onDom then return
    
  getPane: -> @parents('.pane').view()
     
  destroy: -> @reader?.destroy()

