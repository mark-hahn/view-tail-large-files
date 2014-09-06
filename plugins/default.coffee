
# plugins/default

# simple built-in default plugin
# only provides basic browser scrolling and tailing
# all possible hook methods are shown even when commented out

fs = require 'fs-plus'

module.exports =
class Default
  
  # called once on beginning of Atom load
  @activate = (@autoOpen) ->
    ViewOpener    = require('../lib/view-opener')

    if @autoOpen
      atom.workspace.registerOpener (filePath, options) =>
        if fs.getSizeSync(filePath) >= 2 * 1048576 
          new ViewOpener filePath
          
  # one instance exists for each view in pane/tab
  constructor: (filePath, @view, @reader, @lineMgr) ->
    if Default.autoOpen
      ProgressView = require '../lib/progress-view'
      progressView = new ProgressView @reader.getFileSize(), @view
      @reader.buildIndex progressView, =>
        setTimeout => 
          progressView.destroy()
          @lineMgr.updateLinesInDOM()
          @lineMgr.watchForNewLines()
          @view.showLines()
        , 300

  # called once for each line found during indexing
  # if any plugin returns false then the line will be ignored
          # approveLine: (view, lineCount, text) -> yes
  
  
  
        
    
    
