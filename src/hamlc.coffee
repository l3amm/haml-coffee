fs = require 'fs'

Compiler       = require './haml-coffee'

if process.title is 'node'
  CoffeeScript = require 'coffee-script'
else
  CoffeeScript = window.CoffeeScript

# Express 3 template Cache
__expressCache = {}

# Facade to Haml Coffee for easy template function
# compiling and JST template rendering.
#
module.exports =

  # Compile the Haml Coffee template into
  # a JavaScript function.
  #
  # @see {Compiler} for a complete list of the supported
  #   compiler options.
  #
  # @param [String] source the Haml Coffee source
  # @param [Object] options the compiler options
  # @return [Function] the template
  #
  compile: (source, options = {}) ->
    compiler = new Compiler(options)
    compiler.parse source

    template = new Function CoffeeScript.compile(compiler.precompile(), bare: true)

    (params) -> template.call params

  # Creates the JavaScript Template.
  #
  # @see {Compiler} for a complete list of the supported
  #   compiler options.
  #
  # @param [String] source the Haml Coffee source
  # @param [Object] options the compiler options
  # @return [String] the template source code
  #
  template: (source, name, namespace, options = {}) ->
    compiler = new Compiler(options)
    compiler.parse source

    CoffeeScript.compile compiler.render(name, namespace)

  # Express 3 templating interface with template function cache.
  # When the template function cache is enabled by setting `cache`
  # in the options to true, the compiled JavaScript template function
  # is cached, which improves speed a lot, since it it only parses,
  # generates and compiles to template once.
  #
  # @overload __express(filename, callback)
  #   Compiles and renders a template
  #   @param [String] filename the template file path
  #   @param [Function] the callback
  #
  # @overload __express(filename, options, callback)
  #   Compiles and renders a template
  #   @param [String] filename the template file path
  #   @param [Object] options the compiler options and template locals
  #   @option options [Boolean] cache whether to cache the template or not
  #   @param [Function] the callback
  #
  __express: (filename, options, callback) ->
    # Parameter shift
    if !!(options and options.constructor and options.call and options.apply)
      callback = options
      options = {}

    try
      if options.cache and __expressCache[filename]
        callback null, __expressCache[filename](options)

      else
        options.filename = filename
        source = fs.readFileSync(filename, 'utf8')

        if options.cache
          __expressCache[filename] = module.exports.compile(source, options)
          callback null, __expressCache[filename](options)

        else
          callback null, module.exports.compile(source, options)(options)

    catch err
      callback err
