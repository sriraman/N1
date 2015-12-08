path = require 'path'
LessCache = require 'less-cache'

# {LessCache} wrapper used by {ThemeManager} to read stylesheets.
module.exports =
class LessCompileCache
  constructor: ({configDirPath, resourcePath, importPaths}) ->
    @lessSearchPaths = [
      path.join(resourcePath, 'static', 'variables')
      path.join(resourcePath, 'static')
    ]

    if importPaths?
      importPaths = importPaths.concat(@lessSearchPaths)
    else
      importPaths = @lessSearchPaths

    @cache = new LessCache
      cacheDir: path.join(configDirPath, 'compile-cache', 'less')
      importPaths: importPaths
      resourcePath: resourcePath
      fallbackDir: path.join(resourcePath, 'less-compile-cache')

  setImportPaths: (importPaths=[]) ->
    @cache.setImportPaths(importPaths.concat(@lessSearchPaths))

  read: (stylesheetPath) ->
    @cache.readFileSync(stylesheetPath)

  cssForFile: (stylesheetPath, lessContent) ->
    @cache.cssForFile(stylesheetPath, lessContent)
