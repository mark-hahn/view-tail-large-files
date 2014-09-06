
# view-opener

path = require 'path'
View = require './file-view'

module.exports =
class ViewOpener
  
  constructor: (@filePath) ->
    
  getFilePath: -> @filePath
  
  # these are required for this to be an Atom file opener
  getViewClass: -> View
  getTitle:     -> '^' + path.basename @filePath

