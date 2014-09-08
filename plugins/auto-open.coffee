
# plugins/auto-open

fs = require 'fs-plus'

module.exports =
class AutoOpen
  
  @activate = ->
    ViewOpener = require '../lib/view-opener'
    atom.workspace.registerOpener (filePath, options) =>
      if fs.getSizeSync(filePath) >= 2 * 1048576 
        new ViewOpener filePath, @
          
  constructor: (filePath, @view, @reader, @lineMgr) ->
    ProgressView = require '../lib/progress-view'
    progressView = new ProgressView @reader.getFileSize(), @view
    @reader.buildIndex progressView, =>
      setTimeout => 
        progressView.destroy()
        @lineMgr.updateLinesInDOM()
        @lineMgr.watchForNewLines()
        @view.showLines()
      , 300
