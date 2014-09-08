
# lib/view-tail-large-files.coffee

pluginMgr = require './plugin-mgr'

pluginMgr.test = 'view-tail-large-files'

module.exports = 
  configDefaults:
    selectPluginsByRegexOnFilePath: 'AutoOpen:.* StickyTail:\\.log$'
    
  activate: -> pluginMgr.activate()
    
  deactivate: -> pluginMgr.deactivate()
