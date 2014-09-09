
# lib\file-reader.coffee

fs        = require 'fs-plus'
pluginMgr = null

bufSize = 16384

module.exports =
class FileReader
  
  constructor: (@filePath) ->
    pluginMgr = require './plugin-mgr'
    @index = []
    @fileSize = 0
    @maxLineLen = 40
 
  getFilePath:   -> @filePath
  getLineCount:  -> @index.length / 2
  getFileSize:   -> fs.getSizeSync @filePath
  getMaxLineLen: -> @maxLineLen
  
  setPlugins: (plugins, view) ->
    @approveLine = pluginMgr.getCall plugins, 'approveLine', view
  
  buildIndex: (progressView, finishedCB) ->
    {index, filePath, isDestroyed} = @
    if isDestroyed then return
    
    filePos = bytesReadTotal = @fileSize
    @fileSize = fileSize = @getFileSize()
    
    bufPos = bufEnd = 0
    buf = new Buffer bufSize
     
    fs.open filePath, 'r', (err, fd) =>
      if err 
        throw new Error 'view-tail-large-files: Error opening ' + filePath + ', ' + err.message
      
      do oneRead = =>
        if @isDestroyed then fs.close fd; return
        
        if bufPos isnt 0
          buf.copy buf, 0, bufPos, bufEnd
          bufEnd -= bufPos
          bufPos = 0
        
        fs.read fd, buf, bufEnd, bufSize - bufEnd, bytesReadTotal, (err, bytesRead) =>
          if err 
            fs.close fd
            throw new Error 'view-tail-large-files: Error reading ' + filePath + ', ' + 
                             bytesReadTotal + ', ' + err.message
          bytesReadTotal += bytesRead
          bufEnd += bytesRead
          
          strPos = 0
          str = buf.toString 'utf8', bufPos, bufEnd
          regex = new RegExp '\\n', 'g'
          
          while (parts = regex.exec str)
            lineText    = str[strPos...regex.lastIndex]
            lineLenByt  = Buffer.byteLength lineText
            strPos      = regex.lastIndex
            filePos    += lineLenByt
            bufPos     += lineLenByt
            if @approveLine index.length/2, lineText
              index.push @lastFilePos ? 0
              index.push filePos
              @maxLineLen = Math.max lineText.length, @maxLineLen
            @lastFilePos = filePos
            
          if bytesReadTotal isnt fileSize 
            if bufPos is 0 
              console.log 'A line is too long (more than ' + bufSize + 'bytes).  ' +
                          'The file will be truncated at line ' + index.length/2 + '.'
              finishedCB()
              fs.close fd
              return
            progressView?.setProgress bytesReadTotal/fileSize, index.length/2
            oneRead()
            
          else
            if filePos < fileSize 
              lineText = str[strPos...]
              if @approveLine index.length/2, lineText
                index.push @lastFilePos ? 0
                index.push fileSize
                @maxLineLen = Math.max lineText.length, @maxLineLen
            progressView?.setProgress 1, index.length/2, @maxLineLen
            finishedCB()
            fs.close fd

  getLines: (start, end) ->
    {index, isDestroyed} = @
    if isDestroyed then return []
    
    idxLen = index.length/2
    if start >= end or start >= idxLen then return []
    end      = Math.min idxLen, end
    startOfs = index[start * 2]
    endOfs   = index[end * 2 - 1]
    bufLen   = endOfs - startOfs
    buf      = new Buffer bufLen
    fd = fs.openSync @filePath, 'r'
    fs.readSync fd, buf, 0, bufLen, startOfs
    fs.close fd
    for lineNum in [start...end]
      buf.toString 'utf8', index[lineNum*2] - startOfs, index[lineNum*2+1] - 1 - startOfs
      
  destroy: -> @isDestroyed = yes

