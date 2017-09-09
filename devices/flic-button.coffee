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
    constructor: (@config, @flic, @channel, lastState) ->
      @_connection_status = lastState?.connection_status?.value or null
      @id = @config.id
      @name = @config.name
      super()
      @upDown = @config.upDown
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
      return unless  @buttons[clickType]?
      return unless timeDiff <= @maxTimeDiff
      @emit @buttons[clickType]

    connectionStatusChanged: (status, reason) =>
      state = if status is 'Ready'
          'Ready'
        else if reason is "BondingKeysMismatch" or
        @_connection_status is "BondingKeysMismatch"
            'Press and Hold'
        else status
      if state is 'Press and Hold' then env.logger.warn "Press and hold #{@id} to reconnect"
      @_connection_status = state
      @emit 'connection_status', state

    destroy: () ->
      @unListen()
      super()


  return FlicButton