
# lib\file-reader.coffee

fs        = require 'fs-plus'
pluginMgr = null

bufSize = 32768

module.exports =
class FileReader
  
  constructor: (@fileView) ->
    {@filePath, @fileViewEmitter} = @fileView
    pluginMgr = require './plugin-mgr'
    @index = []
    @fileSize = 0
    @textMaxChrCount = 40
 
  getFileSize:        -> fs.getSizeSync @filePath
  getLineCount:       -> @index.length
  getTextMaxChrCount: -> @textMaxChrCount
  
  buildIndex: (progressView, finishedCB) ->
    if @isDestroyed then return
    
    {index, filePath} = @
    @lastFilePos = filePos = bytesReadTotal = @fileSize
    @fileSize = fileSize = @getFileSize()
    
    bufPos = bufEnd = 0
    buf = new Buffer bufSize
     
    fs.open filePath, 'r', (err, fd) =>
      if err 
        throw new Error "view-tail-large-files: Error opening #{filePath}, #{err.message}"
      
      if @isDestroyed then fs.close fd; return
      
      do oneRead = =>
        if bufPos isnt 0
          buf.copy buf, 0, bufPos, bufEnd
          bufEnd -= bufPos
          bufPos = 0
        
        fs.read fd, buf, bufEnd, bufSize - bufEnd, bytesReadTotal, (err, bytesRead) =>
          if err 
            fs.close fd
            throw new Error "view-tail-large-files: Error reading " +
                            "#{filePath}, #{bytesReadTotal}, #{err.message}"
          bytesReadTotal += bytesRead
          bufEnd += bytesRead
          
          console.log 'read bytes', bytesReadTotal
          
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
            index.push (filePos - @lastFilePos) * 0x100000000 + filePos
            @textMaxChrCount = Math.max lineText.length, @textMaxChrCount
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
              index.push (fileSize - @lastFilePos) * 0x100000000 + fileSize
              @textMaxChrCount = Math.max lineText.length, @textMaxChrCount
            progressView?.setProgress 1, index.length, @textMaxChrCount
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
      stripCR = (if buf[lineEndOfs-startOfs-1] is 13 then 1 else 0)
      buf.toString 'utf8', lineBegOfs - startOfs, lineEndOfs - stripCR - startOfs
      
  destroy: -> 
    @isDestroyed = yes
    delete @index
    console.log 'reader destroyed'


