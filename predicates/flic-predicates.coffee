module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  M = env.matcher

  class FlicButtonPredicateHandler extends env.predicates.PredicateHandler
    constructor: (@provider, @device, @event) ->
      assert @device?
      assert @event?
      @dependOnDevice(@device)

    setup: ->
      @flicEventListener = ( => @emit 'change', 'event')
      @device.on "#{@event}", @flicEventListener
      super()

    getValue: -> Promise.resolve(false)
    destroy: ->
      @device.removeListener "#{@event}", @flicEventListener
      super()
    getType: -> 'event'

  class FlicButtonPredicateProvider extends env.predicates.PredicateProvider
    presets: [{
      name: "flic button"
      input: "{flic} is {type}"
    }]

    constructor: (@framework) ->
    parsePredicate: (input, context) ->
      matchFlic = null
      matchEvent = null
      buttonsWithId = []
      eventTypes = []
      for id, d of @framework.deviceManager.devices when d.config.class is 'FlicButton'
        buttonsWithId.push [{flic: d}, d.id]
      m = M(input, context)
        .match buttonsWithId, type: 'select', wildcard: "{flic}", (next,  {flic}) =>
          matchFlic = flic
          eventTypes.push [type: t, t] for t in matchFlic.events
          m = next
      m = m.match(' is ')
      m = m.match(eventTypes, type: 'select', wildcard: "{type}", ((m, {type}) => matchEvent = type))
      if m.hadMatch()
        match = m.getFullMatch()
        return {
          token: match
          nextInput: input.substring(match.length)
          predicateHandler: new FlicButtonPredicateHandler(this, matchFlic, matchEvent)
        }
      return null

  return FlicButtonPredicateProvider