module.exports = (env) ->
  Promise = env.require 'bluebird'

  class FlicButton extends env.devices.Device
    attributes:
      connection_status:
        description: "Button Connection Status"
        label: "Status"
        type: "string"
    getConnection_status: -> Promise.resolve(@_connection_status)
    @property "daemonID",
      get: -> @config.daemonID
      set: (id) -> @config.daemonID = id

    _connection_status: null
    constructor: (@config, @flic, @channel, isNew=false) ->
      @id = @config.id
      @name = @config.name
      super()
      @bdAddr = @config.bdAddr
      @maxTimeDiff = @config.maxTimeDiff
      @buttons =
        ButtonSingleClick: "single-clicked"
        ButtonDoubleClick: "double-clicked"
        ButtonHold: "held"
      if @upDown
        @buttons.ButtonDown = "pressed-down"
        @buttons.ButtonUp = "released"
      @events = (val for key, val of @buttons)
      @listen()

    listen: =>
      @channel.on 'buttonSingleOrDoubleClickOrHold', @flicPressed
      @channel.on 'buttonUpOrDown', @flicPressed if @upDown
      @channel.on 'connectionStatusChanged', @connectionStatusChanged
      return null
    unListen: =>
      @channel.removeListener 'buttonSingleOrDoubleClickOrHold', @flicPressed
      @channel.removeListener 'buttonUpOrDown', @flicPressed if @upDown
      @channel.removeListener 'connectionStatusChanged', @connectionStatusChanged
      return null

    flicPressed: (clickType, wasQueued, timeDiff) =>
      console.log @daemonID, @buttons[clickType]
      return unless  @buttons[clickType]?
      console.log @daemonID, @buttons[clickType]
      return unless timeDiff <= @maxTimeDiff
      console.log @daemonID, @buttons[clickType]
      @emit @buttons[clickType]

    connectionStatusChanged: (status, reason) =>
      @_connection_status = status
      @emit 'connection_status', status
      return null

    destroy: () ->
      @unListen()
      super()


  return FlicButton