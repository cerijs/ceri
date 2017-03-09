fs = require "fs"
path = require "path"
acorn = require "acorn"
coffee = require "coffee-script"
src = path.resolve(__dirname, "./src")
lib = path.resolve(__dirname, "./lib")

replaceExpression = (js, expr, cb) ->
  indexOffset = 0
  while (indexOffset = js.indexOf(expr+"(",indexOffset)) > -1
    node =  acorn.parseExpressionAt(js, indexOffset)
    if node.type == "SequenceExpression"
      node = node.expressions[0]
    try
      js = cb(js, node)
    catch e
      console.error e
    indexOffset++
  return js

changing = {}
compile = (file) ->
  unless changing[file]
    outFile = path.resolve(lib, path.basename(file,".coffee"))+".js"
    changing[file] = true
    setTimeout (-> changing[file] = false), 1000
    fs.readFile file, 'utf8', (err, sourceCoffee) ->
      throw err if err?
      sourceJS = coffee.compile sourceCoffee,
        filename: file,
        bare: true,
        generatedFile: outFile
      tests = 0
      sourceJS = replaceExpression sourceJS, "test", (js, node) ->
        tests++
        return js.substr(0,node.start) + js.substr(node.end)
      fs.writeFile outFile, sourceJS, (err) ->
        changing[file] = false
        throw err if err?
        console.log "compiled #{file} to #{outFile} - #{tests} tests removed"

if process.argv[2] == "--watch"
  chokidar = require "chokidar"
  chokidar.watch src
  .on "add", compile
  .on "change", compile
else
  fs.readdir src, (err, files) ->
    throw err if err?
    files.forEach (file) -> compile(path.resolve(src,file))
