/*!
 * nib
 * Copyright (c) 2010 TJ Holowaychuk <tj@vision-media.ca>
 * MIT Licensed
 */

/**
 * Module dependencies.
 */

var stylus = require('stylus'),
    path = require('path'),
    less2stylus = require('less2stylus'),
    nodes = stylus.nodes,
    utils = stylus.utils;

exports = module.exports = plugin;

/**
 * Library version.
 */

exports.version = require(path.join(__dirname, '../package.json')).version;

/**
 * Stylus path.
 */

exports.path = __dirname;

/**
 * Return the plugin callback for stylus.
 *
 * @return {Function}
 * @api public
 */

function plugin() {
  return function(style){
    //console.log(style.deps())
    //console.log(style, nodes, utils);
    //console.log(stylus.render(style.str))
    return 'a'
  };
}
