$ = $$ = fs = _s = Q = _ = null
ResizableView = require './resizable-view'
TagGenerator = require './tag-generator'

module.exports =
class CoffeeNavigatorView extends ResizableView
  @innerContent: ->
    @div id: 'coffee-navigator', class: 'padded', =>
      @div outlet: 'tree'

  initialize: (serializeState) ->
    super serializeState

    @showOnRightSide = atom.config.get('coffee-navigator.showOnRightSide')
    atom.config.onDidChange 'coffee-navigator.showOnRightSide', ({newValue}) =>
      @onSideToggled(newValue)

    atom.commands.add 'atom-workspace', 'coffee-navigator:toggle', => @toggle()
    atom.workspace.onDidChangeActivePaneItem =>
      if @visible
        @show()
    @visible = localStorage.getItem('coffeeNavigatorStatus') == 'true'
    if @visible
      @show()

    @debug = false

  serialize: ->

  destroy: ->
    @detach()

  toggle: ->
    if @isVisible()
      @detach()
    else
      @show()

    localStorage.setItem 'coffeeNavigatorStatus', @isVisible()

  show: ->
    @attach()
    @parseCurrentFile()
    @focus()

  attach: ->
    _ ?= require 'underscore-plus'
    return if _.isEmpty(atom.project.getPaths())

    @panel ?=
      if @showOnRightSide
        atom.workspace.addRightPanel(item: this)
      else
        atom.workspace.addLeftPanel(item: this)

  detach: ->
    @panel.destroy()
    @panel = null

  onSideToggled: (newValue) ->
    @closest('.view-resizer')[0].dataset.showOnRightSide = newValue
    @showOnRightSide = newValue
    if @isVisible()
      @detach()
      @attach()

  getPath: ->
    # Get path for currently edited file
    atom.workspace.getActiveEditor()?.getPath()

  getScopeName: ->
    # Get grammar scope name
    atom.workspace.getActiveEditor()?.getGrammar()?.scopeName

  log: ->
    if @debug
      console.log arguments

  parseCurrentFile: ->
    _s ?= require 'underscore.string'
    $ ?= require('atom').$
    $$ ?= require('atom').$$

    scrollTop = @.scrollTop()
    @tree.empty()

    new TagGenerator(@getPath(), @getScopeName()).generate().done (tags) =>
      lastIdentation = -1
      for tag in tags
        if tag.identation > lastIdentation
          root = if @tree.find('li:last').length then @tree.find('li:last') else @tree
          root.append $$ ->
            @ul class: 'list-tree'
          root = root.find('ul:last')
        else if tag.identation == lastIdentation
          root = @tree.find('li:last')
        else
          root = @tree.find('li[data-identation='+tag.identation+']:last').parent()

        icon = ''
        switch tag.kind
          when 'function' then icon = 'icon-unbound'
          when 'function-bind' then icon = 'icon-bound'
          when 'class' then icon = 'icon-class'

        if _s.startsWith(tag.name, '@')
          tag.name = tag.name.slice(1)
          if tag.kind == 'function'
            icon += '-static'
        else if tag.name == 'module.exports'
          icon = 'icon-package'

        root.append $$ ->
            @li class: 'list-nested-item', 'data-identation': tag.identation, =>
              @div class: 'list-item', =>
                @a
                  class: 'icon ' + icon
                  "data-line": tag.position.row
                  "data-column": tag.position.column, tag.name

        lastIdentation = tag.identation

      @.scrollTop(scrollTop)


      @tree.find('a').on 'click', (el) ->
        line = parseInt($(@).attr 'data-line')
        column = parseInt($(@).attr 'data-column')
        editor = atom.workspace.getActiveEditor()

        editor.setCursorBufferPosition [line, column]
        firstRow = editor.getFirstVisibleScreenRow()
        editor.scrollToBufferPosition [line + (line - firstRow) - 1, column]


  renderCurrentFile: ->
    fs ?= require 'fs'

    activeEditor = atom.workspace.getActiveEditor()
    if (!!activeEditor) && (fs.existsSync(activeEditor.getPath()))
      _s ?= require 'underscore.string'
      if _s.endsWith(activeEditor.getPath(), '.coffee')
        promise = @getActiveEditorView()
        promise.then (activeEditorView) =>

          activeEditorView.className += ' has-navigator'
          div = document.createElement 'div'
          div.innerHTML = @.html()
          activeEditorView.appendChild @

          console.log('getActiveEditorView', activeEditorView);

          # contents-modified for "live" parsing
          activeEditor.getBuffer().on 'saved', @onChange



  _hide: ->
    if @hasParent()
      @.parent().removeClass 'has-navigator'
      @.parent()[0].getModel().getBuffer().off 'saved', @onChange
      @detach()

  onChange: =>
    @parseCurrentFile()
