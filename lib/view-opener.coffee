
# view-opener

path = require 'path'
View = require './file-view'

module.exports =
class ViewOpener
  
  constructor: (@filePath, @creatorPlugin) ->
    
  getFilePath:        -> @filePath
  getCreatorPlugin:   -> @creatorPlugin
  
  # these are required for this to be an Atom file opener
  getViewClass: -> View
  getTitle:     -> '^' + path.basename @filePath
