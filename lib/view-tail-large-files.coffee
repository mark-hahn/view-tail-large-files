
# lib\view-tail-large-files.coffee

fs     = require 'fs-plus'
Reader = require './file-reader'

class LargeFiles
  
  activate: ->
    # console.log 'view-tail-large-files activated'
    atom.workspace.registerOpener @openUri
      
  openUri: (@filePath, options) ->
    size = fs.getSizeSync @filePath
    if size >= 2 * 1048576 
      # console.log 'view-tail-large-files opening large file:', @filePath
      @reader = new Reader @filePath, size 
    
  deactivate: -> 
    # console.log 'view-tail-large-files deactivated', @filePath
    @reader?.destroy()

module.exports = new LargeFiles
