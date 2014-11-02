class Outer
  x: -> undefined
  class Inner
    y: -> undefined

module.exports = ->
  class ClassInFunction
    z: -> undefined
  class SecondClassInFunction
    a: -> undefined
    b: -> undefined
