
# view-opener

path = require 'path'

FileView = null

module.exports =
class ViewOpener
  
  constructor: (@filePath, @creatorPlugin) ->
    FileView = require './file-view'
    
  getFilePath:        -> @filePath
  getCreatorPlugin:   -> @creatorPlugin
  
  # these are required for this to be an Atom view opener
  getViewClass: -> FileView
  getTitle:     -> '^' + path.basename @filePath
