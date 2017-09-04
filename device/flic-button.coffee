module.exports = (env) ->
  Promise = env.require 'bluebird'

  createButtons = (id) ->
    return [
      {text: 'ButtonSingleClick', id: "#{id}-single-click", include: yes}
      {text: 'ButtonDoubleClick', id: "#{id}-double-click", include: yes}
      {text: 'ButtonHold',        id: "#{id}-hold",         include: yes}
      {text: 'ButtonClick',       id: "#{id}-click",        include: no}
      {text: 'ButtonDown',        id: "#{id}-down",         include: no}
      {text: 'ButtonUp',          id: "#{id}-up",           include: no}
    ]


  class FlicButton extends env.devices.ButtonsDevice
    _connection_status: null
    attributes:
      connection_status:
        description: "Button Connection Status"
        label: "Status"
        type: "string"
    getConnection_status: -> Promise.resolve(@_connection_status)


    constructor: (@config, @flic)->
      {@id, @daemon, @name, @hwAddress, @maxTimeDiff, @connectionOptions} = @config



      super(@config)
      console.log "daemon"
      console.log @daemon
      @buttons = {}
      @buttons[b.text] = b.id for b in @config.buttons when b.include
      @listening = no
      @listener = null



    listen: (cc) =>
      @listening = yes
      @listener = cc
      if @buttons['ButtonUp']? or @buttons['ButtonDown']
        @listener.on 'buttonUpOrDown', @buttonPressed
      if @buttons['ButtonSingleClick']? or @buttons['ButtonDoubleClick'] or @buttons['ButtonHold']
        @listener.on 'buttonSingleOrDoubleClickOrHold', @buttonPressed
      #      if @daemon.debug
      #        @listener.on "connectionStatusChanged", @connectionStatusChanged
      @listener.on 'removed', @handleRemoved
      return

    handleRemoved: (reason) =>
      console.log reason
      return if reason is 'RemovedByThisClient'
      @listening = false
      return

    buttonPressed: (clickType, wasQueued, timeDiff) =>
      return unless timeDiff <= @maxTimeDiff and @buttons[clickType]?
      console.log clickType, wasQueued, timeDiff
      @_lastPressedButton = @buttons[clickType]
      @emit 'button', @buttons[clickType]
      return

    connectionStatusChanged: (status, reason) =>
      env.logger.info "connectionStatusChanged #{@id} #{status} #{if status is "Disconnected" then " #{reason}" else ""}"
      @_connection_status = status
      @emit 'connection_status', status
      return


    destroy: () =>
      @flic.destroyButton(@)
      super()


  return FlicButton