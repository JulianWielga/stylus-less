stylus = require 'stylus'
path = require 'path'
less = require 'less'
fs = require 'fs'
crypto = require 'crypto'
{extend, isString} = require 'underscore'

nodes = stylus.nodes
utils = stylus.utils


readLess = (filename, callback) ->
  parser = new less.Parser(filename: filename)
  str = fs.readFileSync(filename).toString()
  parser.parse str, (err, node) ->
    if err
      console.log str
      throw err
    callback renderStylus(node)

importLess = (path) ->
  path = path.toJSON().val
  path = utils.lookup(path, @options.paths)
  if path
    readLess path, (str) =>
      block = new nodes.Block()
      parser = new stylus.Parser(str, utils.merge(root: block, @options))

      try
        block = parser.parse()
      catch err
        line = parser.lexer.prev.lineno
        column = parser.lexer.prev.column
        err.filename = file
        err.lineno = line
        err.column = column
        err.input = str
        throw err

      block = block.clone @renderer.options.parent
      block.parent = @renderer.options.parent
      block.scope = false

      block.push @visit block


Plugin = ->
  (style) ->
    style.include __dirname
    style.define 'importLess', importLess

extend Plugin,
  path: __dirname
  version: require(path.join(__dirname, '../package.json')).version


exports = module.exports = Plugin


class BaseVisitor
  visitAlpha: (node) ->
    throw new Error('not implemented')

  visitAnonymous: (node) ->
    throw new Error('not implemented')

  visitAssigment: (node) ->
    throw new Error('not implemented')

  visitAttribute: (node) ->
    throw new Error('not implemented')

  visitCall: (node) ->
    throw new Error('not implemented')

  visitColor: (node) ->
    throw new Error('not implemented')

  visitComment: (node) ->
    throw new Error('not implemented')

  visitCondition: (node) ->
    throw new Error('not implemented')

  visitDimension: (node) ->
    throw new Error('not implemented')

  visitDirective: (node) ->
    throw new Error('not implemented')

  visitElement: (node) ->
    throw new Error('not implemented')

  visitExpression: (node) ->
    throw new Error('not implemented')

  visitExtend: (node) ->
    throw new Error('not implemented')

  visitImport: (node) ->
    throw new Error('not implemented')

  visitJavaScript: (node) ->
    throw new Error('not implemented')

  visitKeyword: (node) ->
    throw new Error('not implemented')

  visitMedia: (node) ->
    throw new Error('not implemented')

  visitMixin: (node) ->
    throw new Error('not implemented')

  visitMixinCall: (node) ->
    throw new Error('not implemented')

  visitMixinDefinition: (node) ->
    throw new Error('not implemented')

  visitNegative: (node) ->
    throw new Error('not implemented')

  visitOperation: (node) ->
    throw new Error('not implemented')

  visitParen: (node) ->
    throw new Error('not implemented')

  visitQuoted: (node) ->
    throw new Error('not implemented')

  visitRule: (node, options) ->
    throw new Error('not implemented')

  visitRuleset: (node, options) ->
    throw new Error('not implemented')

  visitSelector: (node, options) ->
    throw new Error('not implemented')

  visitValue: (node) ->
    throw new Error('not implemented')

  visitVariable: (node) ->
    throw new Error('not implemented')

  visitURL: (node) ->
    throw new Error('not implemented')

  visitUnicodeDescriptor: (node) ->
    throw new Error('not implemented')

genVar = ->
  "var#{crypto.randomBytes(12).toString('hex')}"

renderValue = (node, options) ->
  options = extend {}, options
  return node if isString node
  impl = new ExpressionVisitor
  impl.options = options
  visitor = new less.tree.visitor impl
  visitor.visit node
  if impl.value then impl.value.trim() else ''


renderTree = (printer, node, indent = '') ->
  impl = new TreeVisitor printer
  impl.indent = indent
  new less.tree.visitor(impl).visit(node)
  return impl

renderMixinParam = (node) ->
  param = node.name.slice(1)
  if node.value
    param = "#{param}=#{renderValue(node.value)}"

renderMixinArg = (node) ->
  param = renderValue(node.value)
  if node.name
    param = "#{node.name.slice(1)}=#{param}"

renderPrelude = ->
  """
  lesscss-percentage(n)
    (n * 100)%
  """.trim()

renderStylus = (node) ->
  printer = new Printer()
  printer.add renderPrelude()
  renderTree(printer, node)
  printer.print()

toUnquoted = (value) ->
  value
  .replace(/@{/g, '"@{')
  .replace(/}/g, '}"')
  .split(/(@{)|}/)
  .filter((v) -> v != '@{' and v != '}' and v?.length > 0)
  .join(' + ')

funcMap =
  '%': 's'
  'percentage': 'lesscss-percentage'

mixinMap =
  translate: 'mixin-translate'
  scale: 'mixin-scale'
  rotate: 'mixin-rotate'
  skew: 'mixin-skew'
  translate3d: 'mixin-translate3d'



class Printer

  add: (str) ->
    @data ?= []
    @data.push str

  print: ->
    @data.join '\n'



class ExpressionVisitor extends BaseVisitor
  acc: (v) ->
    @value = '' unless @value
    @value += ' ' + v

  visitAnonymous: (node) ->
    @acc node.value

  visitDimension: (node) ->
    @acc "#{node.value}#{node.unit.numerator.join('')}"

  visitVariable: (node) ->
    if @options.unquote
      @acc "@{#{node.name.slice(1)}}"
    else
      @acc node.name.slice(1)

  visitCall: (node, options) ->
    options.visitDeeper = false
    args = node.args.map((e) => renderValue(e, @options)).join(', ')
    name = funcMap[node.name] or node.name
    args = args.replace(/%d/g, '%s') if name == 's'
    @acc "#{name}(#{args})"

  visitSelector: (node, options) ->
    options.visitDeeper = false
    str = node.elements
      .map((e) =>
        "#{e.combinator.value}#{renderValue(e, @options)}")
      .join('')
      .replace(/>/g, ' > ')
      .replace(/\+/g, ' + ')
    @acc str

  visitElement: (node, options) ->
    options.visitDeeper = false
    @acc renderValue(node.value, @options)

  visitAttribute: (node, options) ->
    options.visitDeeper = false
    rendered = node.key
    rendered += node.op + renderValue(node.value, @options) if node.op
    @acc "[#{rendered}]"

  visitKeyword: (node) ->
    @acc node.value

  visitQuoted: (node) ->
    if node.escaped
      value = toUnquoted(node.value)
      @acc "unquote(#{node.quote}#{value}#{node.quote})"
    else
      @acc "#{node.quote}#{node.value}#{node.quote}"

  visitParen: (node, options) ->
    options.visitDeeper = false
    @acc "(#{renderValue(node.value, @options)})"

  visitRule: (node, options) ->
    options.visitDeeper = false
    @acc "#{node.name}: #{renderValue(node.value, @options)}"

  visitOperation: (node, options) ->
    options.visitDeeper = false
    if node.operands.length != 2
      throw new Error('assertion')
    [left, right] = node.operands
    value = "#{renderValue(left, @options)} #{node.op} #{renderValue(right, @options)}"
    value = "(#{value})"
    @acc value

  visitValue: (node, options) ->
    options.visitDeeper = false
    @acc node.value.map((e) => renderValue(e, @options)).join(', ')

  visitExpression: (node, options) ->
    options.visitDeeper = false
    @acc node.value.map((e) => renderValue(e, @options)).join(' ')

  visitColor: (node) ->
    if node.rgb
      c = "rgb(#{node.rgb.join(', ')}"
      if node.alpha
        c += ", #{node.alpha}"
      c += ")"
      @acc c
    else
      throw new Error("unknow color #{node}")

  visitNegative: (node) ->
    @acc "- #{renderValue(node.value, @options)}"


class TreeVisitor extends BaseVisitor
  indent: ''

  constructor: (@printer) ->

  increaseIndent: ->
    @indent + '  '

  decreaseIndent: ->
    @indent.slice(0, -2)

  p: (m, indent) ->
    indent = indent or @indent
    @printer.add "#{indent}#{m.trim()}"

  isNamespaceDefinition: (node) ->
    return false unless node.type == 'Ruleset'
    return false unless node.selectors.length == 1
    name = renderValue node.selectors[0]
    return false unless name[0] == '#'
    return false unless node.rules.every (rule) ->
      # TODO: variables are also allowed
      rule.type == 'MixinDefinition' or rule.type == 'Comment'
    return name.slice(1)

  isNamespaceCall: (node) ->

  visitRuleset: (node, options, directive = '') ->
    unless node.root
      namespace = @isNamespaceDefinition(node)
      options.visitDeeper = false
      if namespace
        for rule in node.rules
          # TODO: handle variables
          if rule.type == 'MixinDefinition'
            rule.name = ".#{namespace}-#{rule.name.slice(1)}"
          renderTree(@printer, rule, @indent)
      else
        if node.rules.length > 0
          res = []
          str = @p "#{directive}#{node.selectors.map(renderValue).join(', ')}"
          res.push str
          for rule in node.rules
            res.push renderTree(@printer, rule, @increaseIndent())
          res

  visitRulesetOut: (node) ->
    unless node.root
      @decreaseIndent()

  visitRule: (node, options) ->
    options.visitDeeper = false
    name = node.name
    if name[0] == '@'
      @p "#{name.slice(1)} = #{renderValue(node.value)}"
    else
      @p "#{name} #{renderValue(node.value)}#{node.important}"

  visitComment: (node) ->
    @p node.value unless node.silent

  visitMedia: (node, options) ->
    options.visitDeeper = false
    features = renderValue(node.features, unquote: true)
    if /@{/.exec features
      mediaVar = genVar()
      @p "#{mediaVar} = \"#{toUnquoted(features)}\""
      @p "@media #{mediaVar}"
    else
      @p "@media #{features}"

    for rule in node.ruleset.rules
      renderTree(@printer, rule, @increaseIndent())

  visitSelector: (node, options) ->
    options.visitDeeper = false
    @p node.elements.map(renderValue).join('')

  visitMixinDefinition: (node, options) ->
    options.visitDeeper = false
    name = node.name.slice(1)
    name = mixinMap[name] or name
    @p "#{name}(#{node.params.map(renderMixinParam).join(', ')})"
    for rule in node.rules
      renderTree(@printer, rule, @increaseIndent())
    if node.params.length == 0 or node.params.every((p) -> p.value?)
      @p ".#{name}"
      @p "#{name}()", @increaseIndent()


  visitMixinCall: (node, options) ->
    options.visitDeeper = false
    if node.selector.elements.length == 2 and node.selector.elements[0].value[0] == '#'
      namespace = node.selector.elements[0].value.slice(1)
      node.selector.elements[0] = node.selector.elements[1]
      delete node.selector.elements[1]
      node.selector.elements[0].value = "#{namespace}-#{node.selector.elements[0].value.slice(1)}"
    name = renderValue(node.selector).slice(1)
    name = mixinMap[name] or name
    if node.arguments.length > 0
      v = "#{renderValue(node.selector).slice(1)}"
      v += "(#{node.arguments.map(renderMixinArg).join(', ')})"
    else
      v = "@extend .#{renderValue(node.selector).slice(1)}"
    @p v

  visitImport: (node, options) ->
    options.visitDeeper = false
    @p "@import #{renderValue(node.path).replace(/\.less/, '.styl')}"

  visitDirective: (node, options) ->
    @visitRuleset(node.ruleset, options, node.name)
