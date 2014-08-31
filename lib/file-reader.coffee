
# lib\file-reader.coffee

fs     = require 'fs-plus'
path   = require 'path'
View   = require './file-view'

halfBufSize = 4096

module.exports =
class FileReader
  
  constructor: (@filePath, @fileSize) ->
    @index = []

  getViewClass: -> View
  getTitle:     -> '^' + path.basename @filePath
  getFileSize:  -> @fileSize
  
  readAndIndex: (progressCB) ->
    {index, filePath, fileSize} = @
    
    filePos = bytesReadTotal = bufPos = bufEnd = 0
    buf = new Buffer 2 * halfBufSize
    
    fs.open filePath, 'r', (err, fd) ->
      if err then throw new error 'error opening long file', filePath, err
      
      calcIndexFromBuf = ->
        strPos = 0
        str = buf.toString 'utf8', bufPos, bufEnd
        regex = new RegExp '\\n', 'g'
        loop 
          if @isDestroyed then return 'done'
          if (parts = regex.exec str)
            filePos += regex.lastIndex - strPos
            bufPos  += Buffer.byteLength str[strPos...regex.lastIndex]
            strPos   = regex.lastIndex
            index.push filePos
            if bufPos > halfBufSize and bytesReadTotal < fileSize 
              progressCB filePos / fileSize, index.length
              return 'read more'
          else
            fs.close fd
            if bytesReadTotal isnt fileSize 
              throw new error 'line too long', filePath, bytesReadTotal, err
            if filePos < fileSize then index.push fileSize
            progressCB 1, index.length
            return 'done'
        null
           
      fs.read fd, buf, 0, 2 * halfBufSize, null, (err, bytesRead) ->
        if err then throw new error 'error in first read of long file', filePath, err
        bytesReadTotal = bufEnd = bytesRead
        if calcIndexFromBuf() is 'done' then return
        
        do oneRead = ->
          buf.copy buf, 0, halfBufSize, 2 * halfBufSize
          bufPos -= halfBufSize
          bufEnd  = halfBufSize
          
          fs.read fd, buf, halfBufSize, halfBufSize, null, (err, bytesRead) ->
            if err then throw new error 'error reading long file', filePath, pos, err
            bytesReadTotal += bytesRead
            bufEnd = halfBufSize + bytesRead
            if calcIndexFromBuf() is 'read more' then oneRead()
            
  getLines: (start, end) ->
    {index} = @
    idxLen = index.length
    if start >= end or start >= idxLen then return []
    end = Math.min idxLen, end
    startOfs = index[start-1] ? 0
    endOfs   = index[end-1]
    bufLen   = endOfs - startOfs
    buf = new Buffer bufLen
    fd = fs.openSync filePath, 'r'
    fs.readSync fd, buf, 0, bufLen, startOfs
    fs.close fd
    for lineNum in [start...end]
      cr = (if lineNum is idxLen-1 then 0 else 1)
      lineBuf = buf.slice (index[lineNum-1] ? 0) - startOfs, (index[lineNum] - cr) - startOfs
      lineBuf.toString()

  destroy: -> @isDestroyed = yes
    
  