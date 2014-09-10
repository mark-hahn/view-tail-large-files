
# lib/view-tail-large-files.coffee

pluginMgr = null

module.exports = 
  configDefaults:
    selectPluginsByRegexOnFilePath: 'AutoOpen: FilePicker: Tail:\.log$'
    
  activate:   -> 
    pluginMgr = require './plugin-mgr'
    pluginMgr.activate()
    
  deactivate: -> 
    pluginMgr.deactivate()
