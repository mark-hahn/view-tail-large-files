
# viewer

path = require 'path'

module.exports =
class Viewer
  
  constructor: (@filePath) ->
    @FileView = require './file-view'
    
  getFilePath: -> @filePath
  
  # these are required for this to be an Atom opener
  getViewClass: -> @FileView
  getTitle:     -> '^' + path.basename @filePath
