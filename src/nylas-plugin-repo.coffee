_ = require 'underscore'
Q = require 'q'
path = require('path')
semver = require 'semver'

BufferedProcess = require './buffered-process'

module.exports =
class NylasPluginRepo

  constructor: ->
    @packagePromises = []

  runCommand: (args, options, callback) ->

    ## TODO: Use npm instead of apm
    #
    # atom-package-manager is the ONLY one of our packages that doesn't
    # natively build under node 4.x! Needed to downgrade from 1.5.0 to 1.3.0
    # to get Node 4.x support
    command = path.join(NylasEnv.resourcePath, "node_modules", ".bin", "apm")

    outputLines = []
    stdout = (lines) -> outputLines.push(lines)
    errorLines = []
    stderr = (lines) -> errorLines.push(lines)
    exit = (code) ->
      callback(code, outputLines.join('\n'), errorLines.join('\n'))

    options ||= {}
    options.env =
      ATOM_API_URL: 'https://edgehill-packages.nylas.com/api'
      ATOM_HOME: NylasEnv.getConfigDirPath()

    # TODO: If we wanted to use npm instaed of apm, all we'd have to do is
    # pass npm the following two arguments and updated Edgehill server to be
    # a npm-spec package registry
    #
    # pluginDir = path.join(NylasEnv.getConfigDirPath(), "packages")
    # args.push("--prefix="+pluginDir)
    #
    # args.push("--registry="+"https://edgehill-packages.nylas.com/")


    if process.platform is "win32"
      options.env["ProgramFiles"] = process.env.ProgramFiles

    args.push('--no-color')

    new BufferedProcess({command, args, stdout, stderr, exit, options})

  runCommandReturningPackages: (args, errorMessage, callback) ->
    @runCommand args, null, (code, stdout, stderr) ->
      if code is 0
        try
          packages = JSON.parse(stdout) ? []
        catch parseError
          error = createJsonParseError(errorMessage, parseError, stdout)
          return callback(error)
        callback(null, packages)
      else
        error = new Error(errorMessage)
        error.stdout = stdout
        error.stderr = stderr
        callback(error)

  loadInstalled: (callback) ->
    args = ['ls', '--json']
    errorMessage = 'Fetching local packages failed.'
    packageProc = @runCommandReturningPackages(args, errorMessage, callback)

    handleProcessErrors(packageProc, errorMessage, callback)

  loadFeatured: (options, callback) ->
    args = ['featured', '--json']
    version = NylasEnv.getVersion()
    args.push('--themes') if options.themes
    args.push('--compatible', version) if semver.valid(version)
    errorMessage = 'Fetching featured packages failed.'

    packageProc = @runCommandReturningPackages(args, errorMessage, callback)
    handleProcessErrors(packageProc, errorMessage, callback)

  loadOutdated: (callback) ->
    args = ['outdated', '--json']
    version = NylasEnv.getVersion()
    args.push('--compatible', version) if semver.valid(version)
    errorMessage = 'Fetching outdated packages and themes failed.'

    packageProc = @runCommandReturningPackages(args, errorMessage, callback)
    handleProcessErrors(packageProc, errorMessage, callback)

  loadPackage: (packageName, callback) ->
    args = ['view', packageName, '--json']
    errorMessage = "Fetching package '#{packageName}' failed."

    packageProc = @runCommandReturningPackages(args, errorMessage, callback)
    handleProcessErrors(packageProc, errorMessage, callback)

  loadCompatiblePackageVersion: (packageName, callback) ->
    args = ['view', packageName, '--json', '--compatible', @normalizeVersion(NylasEnv.getVersion())]
    errorMessage = "Fetching package '#{packageName}' failed."

    packageProc = @runCommandReturningPackages(args, errorMessage, callback)
    handleProcessErrors(packageProc, errorMessage, callback)

  getInstalled: ->
    Promise.promisify(@loadInstalled, this)()

  getFeatured: (options = {}) ->
    Promise.promisify(@loadFeatured, this)(options)

  getOutdated: ->
    Promise.promisify(@loadOutdated, this)()

  getPackage: (packageName) ->
    @packagePromises[packageName] ?= Promise.promisify(@loadPackage, this, packageName)()

  satisfiesVersion: (version, metadata) ->
    engine = metadata.engines?.nylas ? '*'
    return false unless semver.validRange(engine)
    return semver.satisfies(version, engine)

  normalizeVersion: (version) ->
    [version] = version.split('-') if typeof version is 'string'
    version

  search: (query, options = {}) ->
    deferred = Promise.defer()

    args = ['search', query, '--json']
    if options.themes
      args.push '--themes'
    else if options.packages
      args.push '--packages'
    errorMessage = "Searching for \u201C#{query}\u201D failed."

    packageProc = @runCommand args, null, (code, stdout, stderr) ->
      if code is 0
        try
          packages = JSON.parse(stdout) ? []
          deferred.resolve(packages)
        catch parseError
          error = createJsonParseError(errorMessage, parseError, stdout)
          deferred.reject(error)
      else
        error = new Error(errorMessage)
        error.stdout = stdout
        error.stderr = stderr
        deferred.reject(error)

    handleProcessErrors packageProc, errorMessage, (error) ->
      deferred.reject(error)

    deferred.promise

  update: (pack, newVersion, callback) ->
    {name, theme} = pack

    if theme
      activateOnSuccess = NylasEnv.packages.isPackageActive(name)
    else
      activateOnSuccess = not NylasEnv.packages.isPackageDisabled(name)
    activateOnFailure = NylasEnv.packages.isPackageActive(name)
    NylasEnv.packages.deactivatePackage(name) if NylasEnv.packages.isPackageActive(name)
    NylasEnv.packages.unloadPackage(name) if NylasEnv.packages.isPackageLoaded(name)

    errorMessage = "Updating to \u201C#{name}@#{newVersion}\u201D failed."
    onError = (error) =>
      error.packageInstallError = not theme
      callback(error)

    args = ['install', "#{name}@#{newVersion}"]
    exit = (code, stdout, stderr) =>
      if code is 0
        if activateOnSuccess
          NylasEnv.packages.activatePackage(name)
        else
          NylasEnv.packages.loadPackage(name)

        callback?()
      else
        NylasEnv.packages.activatePackage(name) if activateOnFailure
        error = new Error(errorMessage)
        error.stdout = stdout
        error.stderr = stderr
        onError(error)

    packageProc = @runCommand(args, null, exit)
    handleProcessErrors(packageProc, errorMessage, onError)

  unload: (packageName) ->
    if NylasEnv.packages.isPackageLoaded(name)
      NylasEnv.packages.deactivatePackage(name) if NylasEnv.packages.isPackageActive(name)
      NylasEnv.packages.unloadPackage(name)

  install: (pack, callback) ->
    {name, version, theme} = pack
    activateOnSuccess = not theme and not NylasEnv.packages.isPackageDisabled(name)
    activateOnFailure = NylasEnv.packages.isPackageActive(name)

    @unload(name)
    args = ['install', "#{name}@#{version}"]

    errorMessage = "Installing \u201C#{name}@#{version}\u201D failed."
    onError = (error) =>
      error.packageInstallError = not theme
      callback(error)

    exit = (code, stdout, stderr) =>
      if code is 0
        if activateOnSuccess
          NylasEnv.packages.activatePackage(name)
        else
          NylasEnv.packages.loadPackage(name)

        callback?()
      else
        NylasEnv.packages.activatePackage(name) if activateOnFailure
        error = new Error(errorMessage)
        error.stdout = stdout
        error.stderr = stderr
        onError(error)

    packageProc = @runCommand(args, null, exit)
    handleProcessErrors(packageProc, errorMessage, onError)

  installDependenciesInPackageDirectory: (dir, callback) ->
    errorMessage = "Failed to install package dependencies."

    exit = (code, stdout, stderr) =>
      if code is 0
        callback?()
      else
        error = new Error(errorMessage)
        error.stdout = stdout
        error.stderr = stderr
        callback(error)

    packageProc = @runCommand(['install'], {cwd: dir}, exit)
    handleProcessErrors(packageProc, errorMessage, callback)

  uninstall: (pack, callback) ->
    {name} = pack

    NylasEnv.packages.deactivatePackage(name) if NylasEnv.packages.isPackageActive(name)

    errorMessage = "Uninstalling \u201C#{name}\u201D failed."
    onError = (error) =>
      callback(error)

    packageProc = @runCommand ['uninstall', '--hard', name], null, (code, stdout, stderr) =>
      if code is 0
        @unload(name)
        callback?()
      else
        error = new Error(errorMessage)
        error.stdout = stdout
        error.stderr = stderr
        onError(error)

    handleProcessErrors(packageProc, errorMessage, onError)

  canUpgrade: (installedPackage, availableVersion) ->
    return false unless installedPackage?

    installedVersion = installedPackage.metadata.version
    return false unless semver.valid(installedVersion)
    return false unless semver.valid(availableVersion)

    semver.gt(availableVersion, installedVersion)

  checkNativeBuildTools: ->
    deferred = Promise.defer()
    packageProc = @runCommand ['install', '--check'], null, (code, stdout, stderr) ->
      if code is 0
        deferred.resolve()
      else
        deferred.reject(new Error())

    packageProc.onWillThrowError ({error, handle}) ->
      handle()
      deferred.reject(error)

    deferred.promise

createJsonParseError = (message, parseError, stdout) ->
  error = new Error(message)
  error.stdout = ''
  error.stderr = "#{parseError.message}: #{stdout}"
  error

createProcessError = (message, processError) ->
  error = new Error(message)
  error.stdout = ''
  error.stderr = processError.message
  error

handleProcessErrors = (packageProc, message, callback) ->
  packageProc.onWillThrowError ({error, handle}) ->
    handle()
    callback(createProcessError(message, error))
