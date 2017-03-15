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
    folder = path.dirname(file).replace(src,lib)
    try
      fs.mkdirSync(folder)
    outFile = path.resolve(folder, path.basename(file,".coffee"))+".js"
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
  processDir = (dir) ->
    fs.readdir dir, (err, entries) ->
      throw err if err?
      entries.forEach (entry) -> 
        name = path.resolve(dir,entry)
        fs.lstat name, (err, stats) ->
          throw err if err?
          if stats.isDirectory()
            processDir(name)
          else if stats.isFile()
            compile(name)
  processDir(src)
