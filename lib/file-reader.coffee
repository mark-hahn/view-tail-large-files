
# lib\file-reader.coffee

fs     = require 'fs-plus'
path   = require 'path'
View   = require './file-view'

bufSize = 16384

module.exports =
class FileReader
  
  constructor: (@filePath, @fileSize) ->
    @index = []
    @maxLineLen = 40
    # console.log 'constructor', {@filePath, @fileSize}

  getViewClass: -> View
  getFilePath:  -> @filePath
  getFileSize:  -> @fileSize
  getTitle:     -> '^' + path.basename @filePath
  
  readAndIndex: (progressCB) ->
    {index, filePath, fileSize, isDestroyed} = @
    if isDestroyed then return
    
    filePos = bytesReadTotal = 0
    if index.length > 0
      filePos  = bytesReadTotal = fileSize
      fileSize = @fileSize = fs.getSizeSync filePath
    
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
        
        fs.read fd, buf, bufEnd, bufSize - bufEnd, bytesReadTotal, (err, bytesRead) ->
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
            lineLenChr  = regex.lastIndex - strPos
            @maxLineLen = Math.max lineLenChr, @maxLineLen
            lineLenByt  = Buffer.byteLength str[strPos...regex.lastIndex]
            strPos      = regex.lastIndex
            filePos    += lineLenByt
            bufPos     += lineLenByt
            index.push filePos
          if bytesReadTotal isnt fileSize 
            progressCB? bytesReadTotal/fileSize, index.length, @maxLineLen
            oneRead()
          else
            if filePos < fileSize then index.push fileSize
            @maxLineLen = Math.max (str.length - strPos), @maxLineLen
            progressCB? 1, index.length, @maxLineLen
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

