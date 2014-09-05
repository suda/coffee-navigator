{View} = require 'atom'
$ = require('atom').$
$$ = require('atom').$$
coffee = require 'coffee-script'
coffeeNodes = require('coffee-script').nodes
fs = require 'fs'
_s = require 'underscore.string'

module.exports =
class CoffeeNavigatorView extends View
  @content: ->
    @div id: 'coffee-navigator', class: 'tool-panel panel-bottom padded', =>
      @ul class: 'list-tree', outlet: 'tree'

  initialize: (serializeState) ->
    atom.workspaceView.command "coffee-navigator:toggle", => @toggle()
    @subscribe atom.workspaceView, 'pane-container:active-pane-item-changed', =>
      if @visible
        @show()

    @visible = false
    # TODO: Hook on file modification

    console.log = ->

  serialize: ->

  destroy: ->
    @detach()

  getActiveEditorView: ->
    editorView for editorView in atom.workspaceView.getEditorViews() when editorView.getEditor() == atom.workspace.getActiveEditor()

  parseBlock: (block) ->
    console.log 'Block', block
    element = $('<div>')
    for expression in block.expressions
      result = null
      switch expression.constructor.name
        when 'Assign' then result = @parseAssign expression
        when 'Value' then result = @parseValue expression

      if !!result
        element.append result
    element.find('>')

  parseValue: (expression) ->
    console.log 'Value', expression
    switch expression.base.constructor.name
      when 'Literal'
        value = expression.base.value
        if expression.properties.length > 0
          for property in expression.properties
            if property.constructor.name != 'Index'
              value += '.' + property.name.value
        return value
      when 'Obj'
        element = $('<div>')
        for obj in expression.base.objects
          result = @parseAssign obj
          if !!result
            element.append result
        return element.find('>')

  parseAssign: (expression) ->
    console.log 'Assign', expression
    element = null
    if expression.value?.constructor.name == 'Code'
      value = @parseValue(expression.variable)
      if expression.value.bound
        icon = 'icon-bound'
      else
        icon = 'icon-unbound'

      element = $$ ->
        @li class: 'list-nested-item', =>
          @div class: 'list-item', =>
            @a class: 'icon ' + icon, "data-line": expression.locationData.first_line, "data-column": expression.locationData.first_column, value
      element.append @parseBlock(expression.value.body)

    else if expression.value?.constructor.name == 'Class'
      className = @parseValue(expression.value.variable)

      element = $$ ->
        @li class: 'list-nested-item', =>
          @div class: 'list-item', =>
            @span class: 'icon icon-class', className
          @ul class: 'list-tree'

      element.find('ul').append @parseBlock(expression.value.body)

    else if expression.base?.constructor.name == 'Obj'
      element = $('<li />')
      element.append @parseValue expression.base

    else if expression.value?.constructor.name == 'Value'
      element = @parseValue expression.value

    element

  parseCurrentFile: ->
    @tree.empty()
    # TODO: Test if path is a file
    # TODO: Test for empty file
    fs.readFile atom.workspace.getActiveEditor().getPath(), (err, code) =>
      try
        nodes = coffee.nodes(code.toString())
        @tree.append @parseBlock(nodes)

        @tree.find('a').on 'click', (el)->
          line = $(@).attr 'data-line'
          column = $(@).attr 'data-column'
          atom.workspace.getActiveEditor().setCursorBufferPosition [line, column]
      catch
        @tree.append $$ ->
          @ul class: 'background-message', =>
            @li 'Error'
            @li 'parsing'
            @li 'file'

  toggle: ->
    if @visible
      @hide()
    else
      @show()

    @visible = !@visible

  show: ->
    if @hasParent()
      @hide()

    activeEditor = atom.workspace.getActiveEditor()
    if !!activeEditor
      activeEditorView = @getActiveEditorView()[0]
      if _s.endsWith(activeEditor.getPath(), '.coffee')
        activeEditorView.addClass 'has-navigator'
        activeEditorView.append(this)

        # contents-modified for "live" parsing
        activeEditor.getBuffer().on 'saved', @onChange

        @parseCurrentFile()

  hide: ->
    if @hasParent()
      @.parent().removeClass 'has-navigator'
      $(@.parent()).data('view').editor.getBuffer().off 'saved', @onChange
      @detach()

  onChange: =>
    @parseCurrentFile()
