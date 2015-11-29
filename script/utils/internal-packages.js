fs = require('fs');
path = require('path');

exports.pluginDirsWithDependencies = function() {
  pluginDirs = []

  root = path.resolve(path.join(__dirname, "..", ".."));
  corePluginDir = path.join(root, "internal_packages");

  fs.readdirSync(corePluginDir).forEach(function(dir) {
    pluginDir = path.join(corePluginDir, dir)
    try {
      var packageJSONPath = path.join(pluginDir, 'package.json');
      if (fs.existsSync(packageJSONPath)) {
        var packageJSON = JSON.parse(fs.readFileSync(packageJSONPath));
        if (packageJSON.dependencies && (Object.keys(packageJSON.dependencies).length > 0)) {
          pluginDirs.push(pluginDir)
        }
      }
    } catch(err){
      console.error(err)
    }
  });

  return pluginDirs;
}

