{View} = require 'atom'
$ = $$ = fs = _s = Q = null
TagGenerator = require './tag-generator'

module.exports =
class CoffeeNavigatorView extends View
  @content: ->
    @div id: 'coffee-navigator', class: 'tool-panel panel-bottom padded', =>
      @div outlet: 'tree'

  initialize: (serializeState) ->
    atom.workspaceView.command 'coffee-navigator:toggle', => @toggle()
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

  getPath: -> atom.workspace.getActiveEditor()?.getPath()

  getScopeName: -> atom.workspace.getActiveEditor()?.getGrammar()?.scopeName

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

  parseCurrentFile: ->
    $ ?= require('atom').$
    $$ ?= require('atom').$$
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

    fs ?= require 'fs'
    activeEditor = atom.workspace.getActiveEditor()
    if (!!activeEditor) && (fs.existsSync(activeEditor.getPath()))
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
