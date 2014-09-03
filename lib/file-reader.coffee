
# lib\file-reader.coffee

fs     = require 'fs-plus'
path   = require 'path'
View   = require './file-view'

halfBufSize = 8192

module.exports =
class FileReader
  
  constructor: (@filePath, @fileSize) ->
    @index = []
    @watcher    = null
    @maxLineLen = 40
    console.log 'constructor', {@filePath, @fileSize}

  getViewClass: -> View
  getFilePath:  -> @filePath
  getFileSize:  -> @fileSize
  getTitle:     -> '^' + path.basename @filePath
  
  readAndIndex: (progressCB) ->
    {index, filePath, fileSize, isDestroyed} = @
    if isDestroyed then return
    
    filePos  = bytesReadTotal = 0
    if index.length > 0
      filePos  = bytesReadTotal = fileSize
      fileSize = @fileSize = fs.getSizeSync filePath
    
    bufPos = bufEnd = 0
    buf = new Buffer 2 * halfBufSize
    
    fs.open filePath, 'r', (err, fd) =>
      if err 
        throw new Error 'view-tail-large-files: Error opening ' + filePath + ', ' + err.message
      
      calcIndexFromBuf = =>
        strPos = 0
        str = buf.toString 'utf8', bufPos, bufEnd
        regex = new RegExp '\\n', 'g'
        loop 
          if (parts = regex.exec str)
            lineLenChr  = regex.lastIndex - strPos
            @maxLineLen =  Math.max lineLenChr, @maxLineLen
            lineLenByt  = Buffer.byteLength str[strPos...regex.lastIndex]
            filePos    += lineLenByt
            bufPos     += lineLenByt
            strPos      = regex.lastIndex
            index.push filePos
            if bufPos > halfBufSize and bytesReadTotal < fileSize 
              progressCB? filePos / fileSize, index.length, @maxLineLen
              return 'read more'
          else
            if bytesReadTotal isnt fileSize 
              fs.close fd
              throw new Error 'view-tail-large-files: line too long ' + filePath + ', ' + bytesReadTotal
            @maxLineLen = Math.max (str.length - strPos), @maxLineLen
            if filePos < fileSize then index.push fileSize
            progressCB? 1, index.length, @maxLineLen
            return 'done'
        null
           
      fs.read fd, buf, 0, 2 * halfBufSize, bytesReadTotal, (err, bytesRead) =>
        if err 
          fs.close fd
          throw new Error 'view-tail-large-files: Error in first read ' + filePath + ', ' + err.message
        bytesReadTotal += bytesRead
        bufEnd = bytesRead
        if calcIndexFromBuf() is 'done' then fs.close fd; return
        
        do oneRead = =>
          if @isDestroyed then fs.close fd; return
          buf.copy buf, 0, halfBufSize, 2 * halfBufSize
          bufPos -= halfBufSize
          
          fs.read fd, buf, halfBufSize, halfBufSize, bytesReadTotal, (err, bytesRead) ->
            if err 
              fs.close fd
              throw new Error 'view-tail-large-files: Error reading ' + filePath + ', ' + 
                               bytesReadTotal + ', ' + err.message
            bytesReadTotal += bytesRead
            bufEnd = halfBufSize + bytesRead
            if calcIndexFromBuf() is 'read more' then oneRead(); return
            fs.close fd
            
  getLines: (start, end) ->
    {index, isDestroyed} = @
    if isDestroyed then return []
    
    idxLen = index.length
    if start >= end or start >= idxLen then return []
    end      = Math.min idxLen, end
    startOfs = index[start-1] ? 0
    endOfs   = index[end-1]
    bufLen   = endOfs - startOfs
    buf      = new Buffer bufLen
    fd = fs.openSync @filePath, 'r'
    fs.readSync fd, buf, 0, bufLen, startOfs
    fs.close fd
    for lineNum in [start...end]
      buf.toString 'utf8', (index[lineNum-1] ? 0) - startOfs, index[lineNum] - 1 - startOfs

  destroy: -> @isDestroyed = yes

