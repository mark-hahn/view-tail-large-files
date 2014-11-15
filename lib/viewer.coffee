
# viewer

{Emitter} = require 'emissary'

path = require 'path'

module.exports =
class Viewer
  
  Emitter.includeInto @
  
  constructor: (@filePath) ->
    @FileView = require './file-view'
    
  getPath: -> @filePath
  
  # these are required for this to be an Atom opener
  getViewClass: -> @FileView
  getTitle:     -> '^' + path.basename @filePath
