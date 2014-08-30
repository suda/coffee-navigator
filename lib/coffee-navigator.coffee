CoffeeNavigatorView = require './coffee-navigator-view'

module.exports =
  coffeeNavigatorView: null

  activate: (state) ->
    @coffeeNavigatorView = new CoffeeNavigatorView(state.coffeeNavigatorViewState)

  deactivate: ->
    @coffeeNavigatorView.destroy()

  serialize: ->
    coffeeNavigatorViewState: @coffeeNavigatorView.serialize()
