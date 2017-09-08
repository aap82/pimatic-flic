module.exports = (env) ->
  Promise = env.require 'bluebird'
  {FlicClient, FlicScanWizard, FlicConnectionChannel} = require("./lib/fliclibNodeJs")

  class FlicDaemon
    createdButtons: => (btn.bdAddr for id, btn of @flic.devices when btn.daemonID is @id)
    @property 'verifiedButtons',
      get: -> @config.verifiedButtons
      set: (btns) -> @config.verifiedButtons = btns

    discover: (created) -> (addr for addr in @verifiedButtons when addr not in created)
    connectToDaemon: =>
      return unless @client is null
      @client = new FlicClient @config.host, @config.port
      @client.on 'bluetoothControllerStateChange', ((state) => @controllerState = state)
      @client.on "error", (error) => @flic.connError(@config, error)
      @client.on 'newVerifiedButton', (bdAddr) =>
        @client.getInfo (info) =>
          @verifiedButtons = info.bdAddrOfVerifiedButtons
          @flic.newVerifiedFlic(@id, bdAddr)
          return
      @client.on 'ready', =>
        @connected = yes
        @flic.logInfo "#{@name} daemon connected"
        @flic.logInfo "#{@name} WHAT WHAT"
        @client.getInfo (info) =>
          @verifiedButtons = info.bdAddrOfVerifiedButtons
          @spaceAvailable = !info.currentlyNoSpaceForNewConnection
          @controllerState = info.bluetoothControllerState
          console.log @name, @verifiedButtons, @createdButtons()
          @connectButton(bdAddr) for bdAddr in @createdButtons()
      @client.on 'close', (errSt) =>
        @flic.logWarn("#{@name} daemon client connection to flic server closed")
        @client = null
        @connections = []
        @connected = no
        if @config.autoReconnect and @retryCount < @config.maxRetries
          console.log 'reconnecting'
          @retryCount++
          @flic.logDebug("#{@name} daemon trying reconnect in #{@config.autoReconnectInterval} seconds")
          @reconnectTimeout = setTimeout (()=> @connectToDaemon()), @config.autoReconnectInterval * 1000

    constructor: (@config, @flic) ->
      @retryCount = 0
      @id = @config.id
      @name = @config.name
      @host = @config.host
      @client = null
      @channels = {}
      @connections = []
      @connected = no
      @spaceAvailable = yes
      @controllerState = null
      @connectToDaemon()

    connectButton: (bdAddr) =>
      return unless @client? and @connected
      if @channels[bdAddr]?
        @client.addConnectionChannel @channels[bdAddr]
        @connections.push bdAddr if bdAddr not in @connections
      return null


    disconnectButton: (bdAddr) =>
      return unless @client?
      if @channels[bdAddr]?
        'removing'
        @client.removeConnectionChannel @channels[bdAddr]
        @connections.remove(bdAddr)
      return null
    createChannel: (bdAddr) =>
      @channels[bdAddr] ?= new FlicConnectionChannel(bdAddr)
      @channels[bdAddr]

    scan: (timeout = 30000) =>
#      daemon.client?.close() for id, daemon of @flic.daemons when id isnt @id
      return new Promise (resolve, reject) =>
        return reject("Not connected to #{@name} daemon. Try again later") unless @client and @connected
        return reject("#{@name} daemon already scanning") if @scanning
        @flic.logInfo "#{@name} daemon scan wizard ready.  Press your Flic button to add it."
        @scanning = yes
        wizard = new FlicScanWizard()
        timeoutId = setTimeout (() => @client.cancelScanWizard(wizard)), timeout
        wizard.on 'foundPrivateButton', =>
          @flic.logInfo 'Your button is private. Hold down for 7 seconds to make it public.'
        wizard.on 'foundPublicButton', (bdAddr, name) =>
          @flic.logInfo 'Found public button ' + bdAddr + ' (' + name + '). Now connecting...'
        wizard.on 'buttonConnected', (bdAddr, name) =>
          @flic.logInfo "Button #{bdAddr} connected. Now verifying and pairing..."
        wizard.on 'completed', (result, bdAddr) =>
          @scanning = no
          clearTimeout(timeoutId)
          @flic.logInfo "#{@name} daemon scan wizard completed with result: #{result}"
          @flic.logInfo "New button is #{bdAddr}" if result is "WizardSuccess"
          return resolve()
        @client.addScanWizard(wizard)

  return FlicDaemon
