
# plugin-mgr

# list of methods looked for in plugins
# values indicate whether more than one plugin may provide this method
# if two plugins conflict, one is randomly allowed to be used
methods =
  includeLine: yes
  newLines:    yes
  scroll:      yes
    
fs   = require 'fs-plus'
path = require 'path'

Plugins = null
do ->
  pluginPaths = fs.listSync path.join __dirname, '..', 'plugins'
  Plugins = 
    for pluginPath in pluginPaths 
      pluginPath =  pluginPath.replace /\.coffee$|\.js$/i, ''
      Plugin = require pluginPath
      Plugin
      
module.exports =  
  error: (msg) ->
    atom.confirm
      message: 'View-Tail-Large-Files Error:\n\n'
      detailedMessage: msg
      buttons['Close']

  activate: -> 
    @regexesStr =  atom.config.get 'view-tail-large-files.selectPluginsByRegexOnFilePath'
    @configRegexesByPluginName = {}
    regex = new RegExp '(^|[\\s;,])?([^\\s;,]+):([^\\s;,]*)([\\s;,]|$)', 'g'
    while (matches = regex.exec @regexesStr)
      pluginName = matches[2]
      regexStr   = matches[3]
      if not regexStr then continue
      pluginName = pluginName.toLowerCase()
      try
        @configRegexesByPluginName[pluginName] =
              new RegExp regexStr.replace /[\-\[\]{}()*+?.,\\\^$|#\s]/g, "\\$&"
      catch 
        @error 'Invalid regex for plugin ' + pluginName + ' in settings.'
    process.nextTick =>
      for Plugin in Plugins when Plugin.name.toLowerCase() of @configRegexesByPluginName
        Plugin.activate?()
      
  deactivate: -> for Plugin in Plugins then Plugin.deactivate?()
      
  getPlugins: (filePath, args...) ->
    pluginsByMethodName = {}
    for Plugin in Plugins
      plugin = null
      
      if (pluginRegex = @configRegexesByPluginName[Plugin.name.toLowerCase()]) and
          pluginRegex.test filePath.replace /\\/g, '/'
        for methodName, multiplePluginsOK of methods when Plugin.prototype[methodName]
          if not pluginsByMethodName[methodName]
            try
              plugin ?= new Plugin filePath, args...
            catch e
              break
            pluginsByMethodName[methodName] = []
          if multiplePluginsOK or plugins[methodName].length is 0
            pluginsByMethodName[methodName].push plugin
    pluginsByMethodName
    
  getCall: (plugins, methodName, view) ->
      if (plugins = plugins[methodName])
        (args...) -> 
          for plugin in plugins
            if plugin[methodName].call(plugin, view, args...) is false 
              return false
          true
      else -> true
