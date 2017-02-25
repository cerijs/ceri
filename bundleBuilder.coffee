fs = require "fs"
path = require "path"
acorn = require "acorn"
lib = path.resolve(__dirname, "./lib")

replaceExpression = (js, expr, cb) ->
  indexOffset = 0
  while (indexOffset = js.indexOf(expr+"(",indexOffset)) > -1
    node =  acorn.parseExpressionAt(js, indexOffset)
    if node.type == "SequenceExpression"
      node = node.expressions[0]
    try
      [js,move] = cb(js, node)
      indexOffset += move
    catch e
      console.error e
      indexOffset++
  return js

changing = {}
cleanFile = (file) ->
  console.log "cleaning #{file}"
  unless changing[file]?
    fs.readFile file, 'utf8', (err, data) ->
      throw err if err?
      data = replaceExpression data, "test", (js, node) ->
        changing[file] = true
        return [js.substr(0,node.start) + js.substr(node.end), node.start + 1]
      if changing[file]?
        fs.writeFile file, data, (err) ->
          delete changing[file]
          throw err if err?

if process.argv[2] == "--watch"
  chokidar = require "chokidar"
  chokidar.watch lib
  .on "add", cleanFile
  .on "change", cleanFile
else
  fs.readdir lib, (err, files) ->
    throw err if err?
    files.forEach (file) -> cleanFile(path.resolve(lib,file))
