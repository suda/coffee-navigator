{View} = require 'atom'
$ = $$ = coffee = coffeeNodes = fs = _s = Q = null

module.exports =
class CoffeeNavigatorView extends View
  @content: ->
    @div id: 'coffee-navigator', class: 'tool-panel panel-bottom padded', =>
      @ul class: 'list-tree', outlet: 'tree'

  initialize: (serializeState) ->
    atom.workspaceView.command 'coffee-navigator:toggle', => @toggle()
    @subscribe atom.workspaceView, 'pane-container:active-pane-item-changed', =>
      if @visible
        @show()
    @visible = localStorage.getItem('coffeeNavigatorStatus') == 'true'
    if @visible
      @show()

    @debug = false

  serialize: ->

  destroy: ->
    @detach()

  log: ->
    if @debug
      console.log arguments

  getActiveEditorView: ->
    Q ?= require 'q'

    deferred = Q.defer()

    # There's slight delay between 'pane-container:active-pane-item-changed'
    # command and creating am EditorView for new pane
    interval = setInterval ->
      for editorView in atom.workspaceView.getEditorViews()
        if editorView.getEditor() == atom.workspace.getActiveEditor()
          deferred.resolve(editorView)
          clearInterval interval
    , 10

    deferred.promise

  parseBlock: (block) ->
    @log 'Block', block
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
    @log 'Value', expression
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
    @log 'Assign', expression
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
            @a
              class: 'icon ' + icon
              'data-line': expression.locationData.first_line
              'data-column': expression.locationData.first_column, value
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
    $ ?= require('atom').$
    $$ ?= require('atom').$$
    coffee ?= require 'coffee-script'
    coffeeNodes ?= require('coffee-script').nodes
    fs ?= require 'fs'

    @tree.empty()

    fs.readFile atom.workspace.getActiveEditor().getPath(), (err, code) =>
      try
        nodes = coffee.nodes(code.toString())
        @tree.append @parseBlock(nodes)
      catch e
        @tree.append $$ ->
          @ul class: 'list-tree', =>
            @li class: 'list-nested-item', =>
              @div class: 'list-item', =>
                @a
                  class: 'icon icon-issue-opened text-error'
                  "data-line": e.location.first_line
                  "data-column": e.location.first_column, e.message

      @tree.find('a').on 'click', (el) ->
        line = parseInt($(@).attr 'data-line')
        column = parseInt($(@).attr 'data-column')
        editor = atom.workspace.getActiveEditor()

        editor.setCursorBufferPosition [line, column]
        firstRow = editor.getFirstVisibleScreenRow()
        editor.scrollToBufferPosition [line + (line - firstRow) - 1, column]

  toggle: ->
    if @visible
      @hide()
    else
      @show()

    @visible = !@visible
    localStorage.setItem 'coffeeNavigatorStatus', @visible

  show: ->
    if @hasParent()
      @hide()

    activeEditor = atom.workspace.getActiveEditor()
    if !!activeEditor
      _s ?= require 'underscore.string'
      if _s.endsWith(activeEditor.getPath(), '.coffee')
        promise = @getActiveEditorView()
        promise.then (activeEditorView) =>
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
