
# lib\file-reader.coffee

fs     = require 'fs-plus'
path   = require 'path'
View   = require './file-view'

halfBufSize = 4096

module.exports =
class FileReader
  
  constructor: (@filePath, @fileSize) ->
    @totalLines = 0
    @index = []

  getViewClass: -> View
    
  getTitle: -> '^' + path.basename @filePath
  
  getSize: -> (@fileSize / (1024*1024)).toFixed(1) + ' MB'
  
  readAndIndex: (progressCB) ->
    {index, filePath, fileSize} = @
    
    bytesReadTotal = bufPos = bufEnd = 0
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
            bufPos += Buffer.byteLength str[strPos...regex.lastIndex]
            strPos  = regex.lastIndex
            index.push bufPos
            progressCB bytesReadTotal / fileSize, index.length
            if bufPos > halfBufSize and 
               bytesReadTotal < fileSize then return 'read more'
          else
            fs.close fd
            if bytesReadTotal isnt fileSize 
              throw new error 'line too long', filePath, bytesReadTotal, err
            index.push fileSize
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
    lines = []
    buf = new Buffer 1024
    fd = fs.openSync filePath, 'r'
    for lineNum in [start ... end]
      beg = index[lineNum-1] ? -1
      len = index[lineNum] - beg
      if len > (buf.length/2) then buf = new Buffer 2 * buf.length
      fs.readSync fd, buf, 0, 
      

  destroy: -> @isDestroyed = yes
    
  