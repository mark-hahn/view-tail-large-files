
# lib\file-view.coffee

{ScrollView} = require 'atom'

chrW = 6
chrH = 19

fs = require 'fs-plus'
fileScroll = require './file-scroll'

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
                      
      @div class:'lines', style:'display:none; background-color:white; 
                                 font-family:courier; font-size:13px'
                  
  
  initialize: (@reader) ->
    super
    @filePath  = @reader.getFilePath()
    $intro     = @find '.intro'
    $introHdr  = @find '.intro-hdr'
    $progBar   = @find '.progress-bar-inner'
    $lineCount = @find '.line-count'
    $lines     = @find '.lines'
    
    fileScroll.init $lines, chrW, chrH

    $introHdr.text 'Opening ' +
                   (@reader.getFileSize() / (1024*1024)).toFixed(1) + ' MB ' + 
                   'file for viewing and tailing ...'
                   
    lastLineCount = 0
    newLines = (lineCount, maxLineLen) =>
      $lines.css width: maxLineLen * chrW, height: (lineCount+1) * chrH + 10
      lines = @reader.getLines lastLineCount, lineCount
      lastLineCount = lineCount
      fileScroll.addLines lines, lineCount, maxLineLen
    
    @reader.readAndIndex (progress, lineCount, maxLineLen) =>
      if not progress? then return
      
      nowSecs = Math.floor Date.now() / 100
      if progress isnt 1 and @lastSecs is nowSecs then return
      @lastSecs =  nowSecs
      
      $lineCount.text 'Lines Indexed: ' + Math.floor(lineCount/1024) + 'K'
      $progBar.css left: -((1 - progress) * 200)
      
      newLines lineCount, maxLineLen
      
      if progress is 1
        setTimeout =>
          $intro.hide()
          $lines.show()
          
          @watch = => 
            @reader.readAndIndex (progress, lineCount, maxLineLen) ->
              if progress isnt 1 then return
              newLines lineCount, maxLineLen
              
          fs.watch @filePath, persistent: no, @watch
        , 300
  
  scrollUp:       -> fileScroll.scrollUp()
  scrollDown:     -> fileScroll.scrollDown() 
  pageUp:         -> fileScroll.pageUp()  
  pageDown:       -> fileScroll.pageDown()
  scrollToTop:    -> fileScroll.scrollToTop()
  scrollToBottom: -> fileScroll.scrollToBottom()
  
  remove: -> 
    @reader?.destroy()
    if @watch then fs.unwatchFile @filePath, @watch

