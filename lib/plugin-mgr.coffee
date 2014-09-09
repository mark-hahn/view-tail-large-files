
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

module.exports =  
  error: (msg) ->
    atom.confirm
      message: 'View-Tail-Large-Files Error:\n\n'
      detailedMessage: msg
      buttons['Close']

  activate: -> 
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
    for pluginName, plugin of Plugins then plugin.PluginClass.activate?()
  
  deactivate: -> 
    for pluginName, plugin of Plugins then plugin.PluginClass.deactivate?()
      
  getPlugins: (filePath, args...) ->
    pluginsByMethodName = {}
    for pluginName, plugin of Plugins
      PluginClass = plugin.PluginClass
      
      if (pluginRegex = plugin.regex) is ''
        new PluginClass filePath, args...
        continue
        
      pluginInst = null
      if pluginRegex.test filePath.replace /\\/g, '/'
        for methodName, multiplePluginsOK of methods when PluginClass.prototype[methodName]
          if not pluginsByMethodName[methodName]
            try
              pluginInst ?= new PluginClass filePath, args...
            catch e
              break
            pluginsByMethodName[methodName] = []
          if multiplePluginsOK or plugins[methodName].length is 0
            pluginsByMethodName[methodName].push pluginInst
            
    # console.log 'pluginsByMethodName', pluginsByMethodName
    pluginsByMethodName
    
  getCall: (plugins, methodName, view) ->
      if (plugins = plugins[methodName])
        (args...) -> 
          for plugin in plugins
            if plugin[methodName].call(plugin, view, args...) is false 
              return false
          true
      else -> true
