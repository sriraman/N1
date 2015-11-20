// Run as
// argv[0] = jasmine JASMINE_CONFIG_PATH=./config.json test APP_PATH=/path/to/electron APP_ARGS=/path/to/app

var babelOptions = require('../static/babelrc.json');
require('babel-core/register')(babelOptions);
jasmine.APP_PATH = process.argv[3].split('APP_PATH=')[1];
jasmine.APP_ARGS = process.argv[4].split('APP_ARGS=')[1].split(',');
jasmine.DEFAULT_TIMEOUT_INTERVAL = 30000;
jasmine.BOOT_WAIT = 15000;
