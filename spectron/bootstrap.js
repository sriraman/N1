// Executed by spec-task.coffee via `npm test`:
//
// argv[0] = node
// argv[1] = jasmine
// argv[2] = JASMINE_CONFIG_PATH=./config.json
// argv[3] = ELECTRON_LAUNCHER=/path/to/electron
// argv[4] = ELECTRON_ARGS=/path/to/app/resource
// argv[5] = NYLAS_ARGS=--test=window,--enable-logging

var babelOptions = require('../static/babelrc.json');
require('babel-core/register')(babelOptions);

jasmine.ELECTRON_LAUNCHER = process.argv[3].split("ELECTRON_LAUNCHER=")[1]
jasmine.ELECTRON_ARGS = process.argv[4].split("ELECTRON_ARGS=")[1].split(',')
jasmine.NYLAS_ARGS = process.argv[5].split("NYLAS_ARGS=")[1].split(',')

jasmine.DEFAULT_TIMEOUT_INTERVAL = 3000000;
jasmine.BOOT_WAIT = 1500000;
