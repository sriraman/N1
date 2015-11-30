var childProcess = require('child_process');

// Exit the process if the command failed and only call the callback if the
// command succeed, output of the command would also be piped.
exports.safeExec = function(command, options, callback) {
  if (!callback) {
    callback = options;
    options = {};
  }
  if (!options)
    options = {};

  // This needed to be increased for test runs that generate many failures
  // The default is 200KB.
  options.maxBuffer = 1024 * 1024;

  var child = childProcess.exec(command, options, function(error, stdout, stderr) {
    if (error && !options.ignoreStderr)
      process.exit(error.code || 1);
    else
      callback(null);
  });
  child.stderr.pipe(process.stderr);
  if (!options.ignoreStdout)
    child.stdout.pipe(process.stdout);
}

// Same with safeExec but call child_process.spawn instead.
exports.safeSpawn = function(command, args, options, callback) {
  if (!callback) {
    callback = options;
    options = {};
  } else {
    options = options || {};
  }
  options.stdio = "inherit"
  var child = childProcess.spawn(command, args, options);
  child.on('error', function(error) {
    console.error('Command \'' + command + '\' failed: ' + error.message);
    console.error(error.stack);
    process.exit(1);
  });
  child.on('exit', function(code) {
    if (code != 0) {
      process.exit(code);
    } else
      callback(null);
  });
}

exports.crossPlatformCommand = function(command) {
  winCommands = {
    "npm": "npm.cmd",
    "grunt": "grunt.cmd"
  }
  if (process.platform === "win32") {
    return winCommands[command] ? winCommands[command] : command
  } else {
    return command
  }
}

exports.safeSpawnP = function(command, args, options) {
  options = options || {};
  args = args || [];
  command = exports.crossPlatformCommand(command)

  return new Promise(function(resolve, reject) {
    from = options.cwd ? " (cwd: "+options.cwd+")" : ""
    console.log("---> $ " + command+" "+args.join(" ")+from);

    exports.safeSpawn(command, args, options, function(){
      return resolve()
    });
  }).catch(function(err){
    console.error(err.message);
    console.error(err.stack);
    process.exit(1);
  });
}

exports.spawnInDirs = function(command, args, dirs) {
  p = Promise.resolve();
  dirs.forEach(function(dir){
    if (typeof args === 'function') {
      argsArr = args(dir);
    } else {
      argsArr = args;
    }
    p = p.then(function(){
      return exports.safeSpawnP(command, argsArr, {cwd: dir})
    }).catch(function(err){
      console.error(err.message);
      console.error(err.stack);
      process.exit(1);
    });
  })
  return p
}
