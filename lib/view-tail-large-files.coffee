
# lib/view-tail-large-files.coffee

class ViewTailLargeFiles
  
  configDefaults:
    selectPluginsByRegexOnFilePath: 'AutoOpen: FilePicker: Tail:\.log$'
  
  activate: (@vtlfState) -> 
    console.log 'activate state', @vtlfState
    
    @pluginMgr = require './plugin-mgr'
    @pluginMgr.activate @vtlfState
    
  serialize: -> @vtlfState
    
  deactivate: -> 
    @pluginMgr.deactivate()

module.exports = new ViewTailLargeFiles
