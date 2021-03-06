webpack = require "webpack"
path = require "path"
module.exports = (config) ->
  config.set
    preprocessors: "test/*.coffee": ["webpack", "sourcemap"]
    webpack:
      devtool: 'inline-source-map'
      resolve:
        extensions: [".js",".coffee"]
      module:
        rules: [
          { test: /\.coffee$/, use: ["coffee-loader"] }
          {
            test: /\.(js|coffee)$/
            use: "ceri-loader"
            enforce: "post"
            exclude: /node_modules/
          }
        ]
      plugins: [
        new webpack.DefinePlugin "process.env.NODE_ENV": JSON.stringify('test')
        new webpack.SourceMapDevToolPlugin
          filename: null
          test: /\.coffee($|\?)/i
      ]
    files: [{pattern: "test/index.coffee", watched: false}]
    frameworks: ["mocha","chai-dom","sinon-chai","ceri"]
    plugins: [
      require("./test/ceri")
      require("karma-sinon-chai")
      require("karma-chai-dom")
      require("karma-chrome-launcher")
      require("karma-firefox-launcher")
      require("karma-mocha")
      require("karma-webpack")
      require("karma-sourcemap-loader")
    ]
    browsers: ["Chromium","Firefox"]
    client:
      mocha:
        {}
        #grep: "with shared objs"
