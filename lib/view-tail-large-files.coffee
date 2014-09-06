
# lib/view-tail-large-files.coffee

pluginMgr = require './plugin-mgr'

pluginMgr.test = 'view-tail-large-files'

module.exports = 
  configDefaults:
    selectPluginsByRegexOnFilePath: 'Example: a-plugin:\\.anExt$  another-plugin:/aFolder/'
    automaticallyOpenFilesTooBigForAtom: yes
    
  activate: -> pluginMgr.activate()
    
  deactivate: -> pluginMgr.deactivate()
