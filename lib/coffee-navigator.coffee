CoffeeNavigatorView = require './coffee-navigator-view'

module.exports =
  config:
    showOnRightSide:
      type: 'boolean'
      default: true

  coffeeNavigatorView: null

  activate: (state) ->
    @coffeeNavigatorView = new CoffeeNavigatorView \
      state.coffeeNavigatorViewState

  deactivate: ->
    @coffeeNavigatorView.destroy()

  serialize: ->
    coffeeNavigatorViewState: @coffeeNavigatorView.serialize()
