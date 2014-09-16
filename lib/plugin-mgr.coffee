
# plugin-mgr

# list of methods looked for in plugins
# values indicate whether more than one plugin may provide this method
# if two plugins conflict, one is randomly allowed to be used
methods =
  includeLine:  yes
  newLines:     yes
  scroll:       yes
  preFileOpen:  yes
  postFileOpen: yes
    
fs   = require 'fs-plus'
path = require 'path'

Plugins = null

module.exports =  
  error: (msg) ->
    atom.confirm
      message: 'View-Tail-Large-Files Error:\n\n'
      detailedMessage: msg
      buttons:['Close']

  activate: (@vtlfState) -> 
    Plugins = {}
    regexesStr =  atom.config.get 'view-tail-large-files.selectPluginsByRegexOnFilePath'
    regexCfg   = new RegExp '(^|[\\s;,])?([^\\s;,]+):([^\\s;,]*)([\\s;,]|$)', 'g'
    while (matches = regexCfg.exec regexesStr)
      pluginNpmName =  'vtlf-' + matches[2].replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase()
      regexStr = matches[3]
      if regexStr is 'off' then continue
      try
        regex =
          if regexStr is '' then ''
          else new RegExp regexStr
        PluginClass = require pluginNpmName
      catch e
        console.log 'view-tail-large-files: Unable to load plugin ' + pluginNpmName + '; ' + e.message
        continue
      PluginClass.name ?= pluginNpmName.replace /\W/g, ''
      Plugins[PluginClass.name] =  {regex, PluginClass}  
    for pluginName, plugin of Plugins
      {PluginClass, regex} = plugin
      PluginClass.activate? @vtlfState, __dirname + '/', @
      if regex is ''
        plugin.PluginClass.singletonInstance = new PluginClass @vtlfState, __dirname + '/', @
    null
  
  deactivate: -> 
    for pluginName, plugin of Plugins then plugin.PluginClass.destroy?()
      
  getPlugins: (filePath, args...) ->
    plugins = []
    pluginsByMethod = {}
    for pluginName, plugin of Plugins
      {PluginClass, regex} = plugin
      
      if (pluginInst = PluginClass.singletonInstance)
        for methodName, multiplePluginsOK of methods when PluginClass.prototype[methodName]
          pluginsByMethod[methodName] ?=  []
          if multiplePluginsOK or pluginsByMethod[methodName].length is 0
            pluginsByMethod[methodName].push pluginInst
        continue
        
      if regex.test filePath.replace /\\/g, '/'
        for methodName, multiplePluginsOK of methods when PluginClass.prototype[methodName]
          if not pluginsByMethod[methodName]
            try
              if not pluginInst
                state = (@vtlfState[pluginName] ?= {})
                pluginInst = new PluginClass state, __dirname + '/', @, filePath, args...
                plugins.push pluginInst
            catch e
              break
            pluginsByMethod[methodName] = []
          if multiplePluginsOK or pluginsByMethod[methodName].length is 0
            pluginsByMethod[methodName].push pluginInst
            
    # console.log 'pluginsByMethod', pluginsByMethod
    [plugins, pluginsByMethod]
    
  getCall: (pluginsByMethod, methodName, view) ->
    if (plugins = pluginsByMethod[methodName]) 
      (args...) -> 
        for plugin in plugins
          if plugin[methodName].call(plugin, view, args...) is false 
            return false
        true
    else -> true
