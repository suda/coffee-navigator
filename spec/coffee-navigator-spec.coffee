{WorkspaceView} = require 'atom'
CoffeeNavigator = require '../lib/coffee-navigator'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "CoffeeNavigator", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('coffee-navigator')

  describe "when the coffee-navigator:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.coffee-navigator')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.workspaceView.trigger 'coffee-navigator:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('.coffee-navigator')).toExist()
        atom.workspaceView.trigger 'coffee-navigator:toggle'
        expect(atom.workspaceView.find('.coffee-navigator')).not.toExist()
