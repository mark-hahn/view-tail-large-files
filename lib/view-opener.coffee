
# view-opener

path = require 'path'

FileView = null

module.exports =
class ViewOpener
  
  constructor: (@filePath, @creator) ->
    FileView = require './file-view'
    
  getFilePath: -> @filePath
  getCreator:  -> @creator
  
  # these are required for this to be an Atom view opener
  getViewClass: -> FileView
  getTitle:     -> '^' + path.basename @filePath
