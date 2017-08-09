module.exports = (env) ->
  Promise = env.require 'bluebird'

  {FlicClient,FlicConnectionChannel,FlicScanWizard} = require("./lib/fliclibNodeJs")
  FlicButton = require('./device/flic-button')(env)

  createFlicClient = ({host, port}) =>
    return new FlicClient host, port


  class FlicDaemonClient
    printDebugMsg: (type,msg) =>
      return unless @debug
      return unless type in ['error', 'info', 'warn']
      return env.logger[type] "daemon: #{@id}: #{msg}"

    constructor: (@id, @config, @plugin) ->
      {@name} = @config
      @defaultLatencyMode = @config.defaultLatencyMode? or @plugin.defaultLatencyMode
      @debug = @config.debug or yes
      @client = null
      @connected = false
      @flicDevices = []
      @bdAddrOfVerifiedButtons = []
      @bluetoothControllerState = null
      @currentlyNoSpaceForNewConnection = false
      @retryCount = 0
      @scanning = no



    connect: =>
      env.logger.info("Connecting to flic daemon")
      return unless @client is null
      @client = createFlicClient(@config)
      @client.on 'ready', @handleConnect
      @client.on 'error', @handleConnectionError
      @client.on 'close', @handleDisconnect
      @client.on 'bluetoothControllerStateChange', @handleBluetoothControllerStateChange
      @client.on 'newVerifiedButton', @handleNewVerifiedButton
      return

    createButton: (config) =>
      if @plugin.buttonExists(config.hwAddress)
        throw new Error("Button with hwAddr of #{@config.hwAddress} already exists")
      button = new FlicButton(config, @)
      @flicDevices.push button
      @addFlicButtonConnectionChannel(button) if config.hwAddress in @bdAddrOfVerifiedButtons
      return button


    handleConnect: =>
      @connected = yes
      @getFlicDaemonInfo(@client).then =>
        @addFlicButtonConnectionChannel(button) for button in @flicDevices
        return Promise.resolve(@client)

    handleDisconnect: =>
      errMsg = "Disconnected from flic daemon."
      console.log @config
      @client = null
      @connected = no
      flicDev.listening = no for flicDev in @flicDevices
      if @config.autoReconnect and @retryCount <= @config.maxRetries
        @retryCount++
        @reconnectTimeout = setTimeout (()=> @connect()), @config.autoReconnectInterval * 1000
        errMsg = errMsg + " Retrying in #{@config.autoReconnectInterval * 1000} seconds"
      env.logger.error(errMsg)
      return @reconnectTimeout


    handleNewVerifiedButton: (hwAddress) =>
      @printDebugMsg 'info', "Button #{hwAddress} successfully connected"
      @bdAddrOfVerifiedButtons.push hwAddress if hwAddress not in @bdAddrOfVerifiedButtons
      for flic in @flicDevices when hwAddress is flic.hwAddress
        @addFlicButtonConnectionChannel(flic)
      return

    handleBluetoothControllerStateChange: (state) => @bluetoothControllerState = state
    handleConnectionError: (error) => env.logger.error "Flic daemon connection error: #{error}"
    addFlicButtonConnectionChannel: (button) =>
      return if @currentlyNoSpaceForNewConnection
      return unless @client? and @connected
      return if button.hwAddress not in @bdAddrOfVerifiedButtons
      return if button.listening
      return if button.buttons is {}
      @printDebugMsg 'info', "Adding Connection Channel for #{button.id} to flic-client"
      cc = new FlicConnectionChannel(button.hwAddress, button.connectionOptions)
      @client.addConnectionChannel(cc)
      button.listen(cc)
      return button

    getFlicDaemonInfo: (client) =>
      return new Promise (resolve) =>
        client.getInfo (info) =>
          console.log info
          {@bdAddrOfVerifiedButtons, @currentlyNoSpaceForNewConnection, @bluetoothControllerState} = info
          return resolve(client)

    destroyButton: (button) =>
      @client.removeConnectionChannel(button.listener) if button.listening
      @flicDevices.splice(@flicDevices.indexOf(button),1)
      return

    startScan: =>
      return if @scanning
      @scanning = yes
      client = createFlicClient(@config)
      client.on 'error', (error) =>
        env.logger.error "Error while trying to discover new buttons: #{error}"
      client.on 'close', =>
        @scanning = no
        env.logger.info "Scan Complete"
      client.on 'ready', =>
        @getFlicDaemonInfo(client).then =>
          @scanWizard(client, 30000)
          return



    scanWizard: (client, timeout) =>
      return new Promise (resolve) =>
        env.logger.info "Please press on flic button to be added to #{@name} daemon within #{timeout/1000} seconds"
        wizard = new FlicScanWizard
        timeoutId = setTimeout (() => client.cancelScanWizard(wizard)), timeout
        wizard.on 'foundPrivateButton', ->
          env.logger.info 'Your button is private. Hold down for 7 seconds to make it public.'
          return
        wizard.on 'foundPublicButton', (bdAddr, name) ->
          env.logger.info 'Found public button ' + bdAddr + ' (' + name + '). Now connecting...'
          return
        wizard.on 'buttonConnected', (bdAddr, name) ->
          env.logger.info "Button #{bdAddr} connected. Now verifying and pairing..."
          return
        wizard.on 'completed', (result, bdAddr) ->
          clearTimeout(timeoutId)
          client.close()
          return resolve()
        client.addScanWizard(wizard)


  return FlicDaemonClient