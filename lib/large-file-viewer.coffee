
# lib\large-file-viewer.coffee

fs     = require 'fs-plus'
Reader = require './file-reader'

class LargeFiles
  
  activate: ->
    console.log 'large-file-viewer activated'
    atom.workspace.registerOpener @openUri
      
  openUri: (@filePath, options) ->
    size = fs.getSizeSync @filePath
    if size >= 2 * 1048576 
      console.log 'large-file-viewer opening large file:', @filePath
      @reader = new Reader @filePath, size 
    
  deactivate: -> 
    console.log 'large-file-viewer deactivated', @filePath
    @reader?.destroy()

module.exports = new LargeFiles
