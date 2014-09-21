
# view-opener

path = require 'path'

FileView = null

module.exports =
class ViewOpener
  
  constructor: (@filePath) ->
    FileView = require './file-view'
    
  getFilePath: -> @filePath
  
  # these are required for this to be an Atom view opener
  getViewClass: -> FileView
  getTitle:     -> '^' + path.basename @filePath
