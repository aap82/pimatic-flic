module.exports = (env) ->
  Promise = env.require 'bluebird'
  paramCase = require 'param-case'

  FlicDaemonClient = require('./flic-daemon')(env)


  createDeviceSchema = (daemons, config) ->
    config.properties.daemon.enum = ("#{daemon.id}" for id, daemon of daemons)
    return config


  class FlicPlugin extends env.plugins.Plugin
    printDebugMsg: (type,msg) =>
      return unless @config.debug
      return unless type in ['error', 'info', 'warn']
      return env.logger[type] "Flic Plugin: #{msg}"


    init: (app, @framework, @config) =>
      @daemons = {}
      if @config.daemons is []
        env.logger.info "Flig Plugin: No daemons provided"
        return
      else
        for daemon,i in @config.daemons
          if daemon.defaultLatencyMode is ""
            @config.daemons[i].defaultLatencyMode = @config.defaultLatencyMode

      daemonHosts = []
      for daemon in @config.daemons
        id = paramCase(daemon.name)
        if @daemons[id]?
          env.logger.error "Flig Plugin: Daemon #{name} listed twice.  Daemon Ids must be unique.  Exiting..."
          return
        if daemon.host in daemonHosts
          env.logger.error "Flig Plugin: Daemon Host #{daemon.host} listed twice.  Daemon Hosts must be unique.  Exiting..."
          return

        daemonHosts.push daemon.host
        @daemons[id] = new FlicDaemonClient(id, daemon, @)



      createScanWizardButton = yes
      for dev in @framework.deviceManager.devicesConfig when dev.class is 'FlicScanWizard'
        createScanWizardButton = no

      if createScanWizardButton
        @framework.deviceManager.devicesConfig.push {
          class: 'FlicScanWizard'
          id: 'flic-scan-wizard'
          name: "Flic Scan Wizard"


        }



      deviceConfigDef = require('./device-config-schema')
      @framework.deviceManager.registerDeviceClass "FlicButton", {
        configDef: createDeviceSchema @daemons, deviceConfigDef.FlicButton
        createCallback: (config) =>
          return @daemons[config.daemon].createButton(config)

      }
      @framework.deviceManager.registerDeviceClass "FlicScanWizard", {
          configDef: deviceConfigDef.FlicScanWizardButton
          createCallback: (config) =>
            return new FlicScanWizardButton(config, @daemons)

    }



      @framework.deviceManager.on "discover", @discover
      @daemons[key].connect() for key, daemon of @daemons

    discover: =>
      return new Promise (resolve) =>
        createdFlics = (dev.hwAddress for dev in @framework.deviceManager.devicesConfig when dev.class is 'FlicButton')
        newButtons = {}
        for key, daemon of @daemons
          console.log daemon.bdAddrOfVerifiedButtons, key
          for id in daemon.bdAddrOfVerifiedButtons when id not in createdFlics
            if not @buttonExists(id)
              newButtons[id] = switch
                when newButtons[id]? then null
                else key
        for id, daemonName of newButtons
          latency = if daemonName is null then @config.defaultLatencyMode else @daemons[daemonName].defaultLatencyMode
          config =
            class: "FlicButton"
            hwAddress: id
            connectionOptions:
              latencyMode:  latency
          if daemonName? then config.daemon = daemonName
          @framework.deviceManager.discoveredDevice 'pimatic-flic', "Flic Button: #{id}", config
        return resolve()

    buttonExists: (hwAddress) =>
      exists = no
      for key, daemon of @daemons
        for button in daemon.flicDevices when button.hwAddress is hwAddress
          exists = yes
          return exists
      return exists




  flicPlugin = new FlicPlugin()

  class FlicScanWizardButton extends env.devices.ButtonsDevice
    constructor: (@config, @daemons) ->
      if @config.id isnt 'flic-scan-wizard'
        throw new Error("Invalid id")
      @id = @config.id
      @name = @config.name
      @config.buttons = ({text: daemon.config.name, id: key} for key, daemon of @daemons)
      super @config

    buttonPressed: (id) =>
      return unless @daemons[id]?
      @daemons[id].startScan()
      return Promise.resolve()




  return flicPlugin