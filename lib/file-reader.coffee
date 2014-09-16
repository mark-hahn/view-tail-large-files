
# lib\file-reader.coffee

fs        = require 'fs-plus'
pluginMgr = null

bufSize = 32768

module.exports =
class FileReader
  
  constructor: (@filePath) ->
    pluginMgr = require './plugin-mgr'
    @index = []
    @fileSize = 0
    @maxLineLen = 40
 
  getFilePath:   -> @filePath
  getLineCount:  -> @index.length
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
      
      if @isDestroyed then fs.close fd; return
      
      do oneRead = =>
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
          
          if @isDestroyed then fs.close fd; return
          
          strPos = 0
          str = buf.toString 'utf8', bufPos, bufEnd
          regex = new RegExp '\\n', 'g'
          
          while (parts = regex.exec str)
            lineText    = str[strPos...regex.lastIndex]
            lineLenByt  = Buffer.byteLength lineText
            strPos      = regex.lastIndex
            filePos    += lineLenByt
            bufPos     += lineLenByt
            if @approveLine index.length, lineText
              index.push (filePos - (@lastFilePos ? 0)) * 0x100000000 + filePos
              @maxLineLen = Math.max lineText.length, @maxLineLen
            @lastFilePos = filePos
            
          if bytesReadTotal < fileSize 
            if bufPos is 0 
              console.log 'A line is too long (more than ' + bufSize + 'bytes).  ' +
                          'The file will be truncated at line ' + index.length + '.'
              finishedCB()
              fs.close fd
              return
            progressView?.setProgress bytesReadTotal/fileSize, index.length
            oneRead()
            
          else
            if filePos < fileSize 
              lineText = str[strPos...]
              if @approveLine index.length, lineText
                index.push (fileSize - (@lastFilePos ? 0)) * 0x100000000 + fileSize
                @maxLineLen = Math.max lineText.length, @maxLineLen
            progressView?.setProgress 1, index.length, @maxLineLen
            finishedCB()
            fs.close fd
            
  getLines: (start, end) ->
    {index, isDestroyed} = @
    if isDestroyed then return []
    
    idxLen = index.length
    if start >= end or start >= idxLen then return []
    end       = Math.min idxLen, end
    startOfs  = (index[start] & 0xffffffff) - Math.floor(index[start] / 0x100000000)
    endOfs    =  index[end-1] & 0xffffffff
    bufLen    = endOfs - startOfs
    buf       = new Buffer bufLen
    fd = fs.openSync @filePath, 'r'
    fs.readSync fd, buf, 0, bufLen, startOfs
    fs.close fd
    for lineNum in [start...end]
      lineEndOfs = index[lineNum] & 0xffffffff
      lineBegOfs = lineEndOfs - Math.floor(index[lineNum] / 0x100000000)
      buf.toString 'utf8', lineBegOfs - startOfs, lineEndOfs - 1 - startOfs
      
  destroy: -> 
    @isDestroyed = yes
    delete @index

