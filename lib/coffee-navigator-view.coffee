{View} = require 'atom'
$ = $$ = = fs = _s = Q = null
TagGenerator = require './tag-generator'

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
      # TODO: Add tags

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
