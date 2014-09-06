
# plugin-mgr

fs   = require 'fs-plus'
path = require 'path'

pluginPaths = fs.listSync path.join __dirname, '..', 'plugins'
Plugins = 
  for pluginPath in pluginPaths 
    pluginPath = pluginPath.replace /\.coffee$|\.js$/i, ''
    Plugin = require pluginPath
    Plugin
    
methodNames = ['includeLine', 'formatLine, filterLine']
methodsWithOnePlugin = ['formatLine, filterLine']

module.exports =  
  error: (msg) ->
    atom.confirm
      message: 'View-Tail-Large-Files Error:\n\n'
      detailedMessage: msg
      buttons['Close']

  activate: -> 
    autoOpen    = atom.config.get 'view-tail-large-files.automaticallyOpenFilesTooBigForAtom'
    @regexesStr = atom.config.get 'view-tail-large-files.selectPluginsByRegexOnFilePath'
    # console.log 'config', {autoOpen, @regexesStr}
    
    @configRegexesByPluginName = {}
    if not /Example:/.test @regexesStr
      for match in @regexesStr.match /(^|[\s;,])[^\s;,]+:[^\s;,]*([\s;,]|$)/i
        [pluginName,regexStr] = match.split ':'
        if not regexStr then continue
        pluginName = pluginName.toLowerCase()
        try
          @configRegexesByPluginName[pluginName] = new RegExp regexStr
        catch 
          @error 'Invalid regex for plugin ' + pluginName + ' in settings.'
      console.log 'configs', {autoOpen, @regexesStr, @configRegexesByPluginName}
    @configRegexesByPluginName.default = /.*/
    process.nextTick =>
      for Plugin in Plugins when Plugin.name.toLowerCase() of @configRegexesByPluginName
        Plugin.activate? autoOpen
      
  deactivate: -> for Plugin in Plugins then Plugin.deactivate?()
      
  getPlugins: (filePath, args...) ->
    pluginsByMethodName = {}
    for Plugin in Plugins 
      haveInstance = no
      if (pluginRegex = @configRegexesByPluginName[Plugin.name.toLowerCase()]) and
          pluginRegex.test filePath.replace /\\/g, '/'
        for methodName in methodNames when Plugin[methodName]
          if not pluginsByMethodName[methodName]
            plugin = new Plugin filePath, args...
            haveInstance = yes
            pluginsByMethodName[methodName] = []
          if methodName in methodsWithOnePlugin and 
              plugins[methodName].length is 0
            pluginsByMethodName[methodName].push plugin
      if Plugin.name is 'Default' and not haveInstance
        new Plugin filePath, args...
    pluginsByMethodName
    
  getCall: (plugins, methodName, view) ->
      if (plugins = plugins[methodName])
        (args...) -> 
          for plugin in plugins
            if plugin[methodName].call(plugin, view, args...) is false 
              return false
          true
      else -> true
