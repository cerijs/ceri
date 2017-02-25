# out: ../lib/index.js
path = require "path"
pattern = (file) ->
  return pattern: file, included: true, served: true, watched: false

framework = (files) ->
  files.unshift pattern __dirname+"/ceri-test"+path.extname(__filename)
framework.$inject = ['config.files']
module.exports = "framework:ceri":["factory",framework]
