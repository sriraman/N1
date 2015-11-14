var babelOptions = require('../static/babelrc.json');
require('babel-core/register')(babelOptions);
jasmine.DEFAULT_TIMEOUT_INTERVAL = 30000;

