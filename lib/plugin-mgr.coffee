
# plugin-mgr

{Emitter} = require 'event-kit'

fs    = require 'fs-plus'
path  = require 'path'
_     = require "underscore"
_.mixin require('underscore.string').exports()

class PluginMgr
  
  onDidOpenFile: (cb) -> @globalEmitter.on 'did-open-file', cb
  
  error: (msg) ->
    atom.confirm
      message: 'View-Tail-Large-Files Error:\n\n'
      detailedMessage: msg
      buttons:['Close']
  
  activate: (@vtlfState) -> 
    @globalEmitter = new Emitter
    
    @plugins = []
    regexesStr = atom.config.get 'view-tail-large-files.selectPluginsByRegexOnFilePath'
    regexCfg   = new RegExp '(^|[\\s;,])?([^\\s;,]+):([^\\s;,]*)([\\s;,]|$)', 'g'
    while (matches = regexCfg.exec regexesStr)
      regexStr = matches[3]
      if regexStr isnt 'off'
        name    = matches[2]
        npmName = 'vtlf-' + matches[2]
        if regexStr is '' 
          try
            PluginClass = require npmName
          catch e
            console.log "view-tail-large-files: Error loading plugin #{name}; #{e.message}"
            continue
          if PluginClass.type isnt 'singleton'
            console.log "view-tail-large-files: Regex missing for #{name}; #{e.message}"
            continue
          pluginState = (@vtlfState[name] ?= {})
          singletonInstance = new PluginClass @, pluginState, __dirname + '/'
          @plugins.push {name, PluginClass, singletonInstance}
        else 
          try
            regex = new RegExp regexStr
          catch e
            console.log "view-tail-large-files: Bad regex '#{regexStr}' " +
                        "for plugin '#{name}'; #{e.message}"
            continue
          @plugins.push {name, npmName, regex}
    null
          
  createPlugins: (fileView) ->
    for plugin in @plugins when not plugin.singletonInstance
      if plugin.regex.test fileView.filePath
        if not plugin.PluginClass
          try
            plugin.PluginClass = require plugin.npmName
          catch e
            console.log "view-tail-large-files: Error loading plugin #{plugin.name}; #{e.message}"
            continue
        pluginState = (@vtlfState[plugin.name] ?= {})
        new plugin.PluginClass fileView, pluginState, __dirname + '/'
  
  destroy: -> 
    for plugin in @plugins
      plugin.PluginClass?.destroy?()
      plugin.singletonInstance?.destroy?()
      

module.exports = new PluginMgr