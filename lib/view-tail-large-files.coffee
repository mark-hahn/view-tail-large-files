
# lib/view-tail-large-files.coffee

class ViewTailLargeFiles
  
  config:
    fontFamily:
      type: 'string'
      default: 'Courier'
    fontSize:
      type: 'integer'
      default: 14
      minimum: 4
    selectPluginsByFilePathRegex:
      type: 'string'
      default: 'file-picker: auto-open: tail:\\.log$'
  
  activate: (@vtlfState) -> 
    # clear state for debugging
    # for key of @vtlfState then delete @vtlfState[key]  
    # console.log 'ViewTailLargeFiles activate @vtlfState', @vtlfState
    
    # there is no "core" code other than the plugin manager
    # only singleton plugins like file-picker and auto-open run at activation
    # other plugins are not loaded until needed for a loaded file
    @pluginMgr = require './plugin-mgr'
    @pluginMgr.activate @vtlfState
    
  serialize: -> @vtlfState
    
  deactivate: -> 
    @pluginMgr.destroy()

module.exports = new ViewTailLargeFiles
