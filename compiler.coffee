fs = require "fs-extra"
path = require "path"
acorn = require "acorn"
coffee = require "coffee-script"
src = path.resolve(__dirname, "./src")
lib = path.resolve(__dirname, "./lib")
lastModified = {}

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
    fs.readFile file, 'utf8'
    .then (sourceCoffee) ->
      sourceJS = coffee.compile sourceCoffee,
        filename: file,
        bare: true,
        generatedFile: outFile
      tests = 0
      sourceJS = replaceExpression sourceJS, "test", (js, node) ->
        tests++
        return js.substr(0,node.start) + js.substr(node.end)
      fs.writeFile outFile, sourceJS
      .then ->
        changing[file] = false
        console.log "compiled #{file} to #{outFile} - #{tests} tests removed"

if process.argv[2] == "--watch"
  chokidar = require "chokidar"
  chokidar.watch src
  .on "add", compile
  .on "change", compile
else
  processDir = (src, lib) ->
    Promise.all [fs.readdir(src), fs.readdir(lib)]
    .then ([srcEntries, libEntries]) ->
      workers = []
      srcEntries.forEach (srcEntry) ->
        srcFilename = path.resolve(src,srcEntry)
        promise = fs.lstat(srcFilename)
          .then (stats) ->
            if stats.isDirectory()
              libFilename = path.resolve(lib,srcEntry)
              fs.ensureDir(libFilename)
              .then -> processDir(srcFilename,libFilename)
            else if stats.isFile() and (libEntries.indexOf(srcEntry.replace(".coffee",".js")) < 0 or not lastModified[srcFilename] or lastModified[srcFilename] != stats.mtime.getTime())
              compile(srcFilename)
              .then ->
                lastModified[srcFilename] = stats.mtime.getTime()
        workers.push promise
        
      for libEntry in libEntries
        if srcEntries.indexOf(libEntry.replace(".js",".coffee")) < 0
          workers.push fs.remove(path.resolve(lib, libEntry))
      Promise.all workers

  start = Date.now()
  fs.readJson("./_lastModified")
  .then (obj) ->
    lastModified = obj
  .catch (e) -> return null
  .then -> processDir(src, lib)
  .then -> fs.writeJson("./_lastModified", lastModified)
  .then ->
    console.log "compilation took: "+(Date.now()-start)+"ms"
  .catch (e) -> console.log e
