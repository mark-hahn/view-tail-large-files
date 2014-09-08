
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
      require pluginPath.replace /\.coffee$|\.js$/i, ''
      
module.exports =  
  error: (msg) ->
    atom.confirm
      message: 'View-Tail-Large-Files Error:\n\n'
      detailedMessage: msg
      buttons['Close']

  activate: -> 
    @regexesStr =  atom.config.get 'view-tail-large-files.selectPluginsByRegexOnFilePath'
    @configRegexByPluginName = {}
    regex = new RegExp '(^|[\\s;,])?([^\\s;,]+):([^\\s;,]*)([\\s;,]|$)', 'g'
    while (matches = regex.exec @regexesStr)
      pluginName = matches[2]
      regexStr   = matches[3]
      if regexStr in ['', 'off'] then continue
      pluginName = pluginName.toLowerCase()
      @configRegexByPluginName[pluginName] = 
        if regexStr is 'on' then 'on'
        else
          try
            new RegExp regexStr
          catch e
            @error 'Invalid regex for plugin ' + pluginName + ' in settings.'
    process.nextTick =>
      for Plugin in Plugins when Plugin.name.toLowerCase() of @configRegexByPluginName
        Plugin.activate?()
      
  deactivate: -> for Plugin in Plugins then Plugin.deactivate?()
      
  getPlugins: (filePath, args...) ->
    pluginsByMethodName = {}
    for Plugin in Plugins
      plugin = null
      if not (pluginRegex = @configRegexByPluginName[Plugin.name.toLowerCase()])
        continue
      if pluginRegex is 'on' then continue
      if pluginRegex.test filePath.replace /\\/g, '/'
        for methodName, multiplePluginsOK of methods when Plugin.prototype[methodName]
          if not pluginsByMethodName[methodName]
            try
              plugin ?= new Plugin filePath, args...
            catch e
              break
            pluginsByMethodName[methodName] = []
          if multiplePluginsOK or plugins[methodName].length is 0
            pluginsByMethodName[methodName].push plugin
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
