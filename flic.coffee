module.exports = (env) ->
  Promise = env.require 'bluebird'
  paramCase = require 'param-case'
  FlicButton = require('./device/flic-button')(env)
  FlicDaemonClient = require('./flic-daemon')(env)
  path = require('path')
  node_ssh = require('node-ssh')
  createButtons = (id) ->
    return [
      {text: 'ButtonSingleClick', id: "#{id}-single-click", include: yes, hidden: yes}
      {text: 'ButtonDoubleClick', id: "#{id}-double-click", include: yes, hidden: yes}
      {text: 'ButtonHold',        id: "#{id}-hold",         include: yes, hidden: yes}
      {text: 'ButtonClick',       id: "#{id}-click",        include: no, hidden: yes}
      {text: 'ButtonDown',        id: "#{id}-down",         include: no, hidden: yes}
      {text: 'ButtonUp',          id: "#{id}-up",           include: no, hidden: yes}
    ]

  createDeviceSchema = (daemons, config) ->
    config.properties.daemon.enum = ("#{daemon.id}" for id, daemon of daemons)
    config.properties.daemon.enum.push "none"

    return config


  class FlicPlugin extends env.plugins.Plugin
    printDebugMsg: (type,msg) =>
      return unless @config.debug
      return unless type in ['error', 'info', 'warn']
      return env.logger[type] "Flic Plugin: #{msg}"


    init: (app, @framework, @config) =>
      @buttons = {}
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
          env.logger.error "Flic Plugin: Daemon #{name} listed twice.  Daemon Ids must be unique.  Exiting..."
          return
        if daemon.host in daemonHosts
          env.logger.error "Flic Plugin: Daemon Host #{daemon.host} listed twice.  Daemon Hosts must be unique.  Exiting..."
          return

        daemonHosts.push daemon.host
        @daemons[id] = new FlicDaemonClient(id, daemon, @)


      createScanWizardButton = yes
      createFlicClearConfig = yes
      for dev in @framework.deviceManager.devicesConfig when dev.class in ['FlicScanWizard', 'FlicClearConfig']
        createFlicClearConfig = no if dev.class is 'FlicClearConfig'
        createScanWizardButton = no if dev.class is 'FlicScanWizard'

      if createScanWizardButton
        @framework.deviceManager.devicesConfig.push {
          class: 'FlicScanWizard'
          id: 'flic-scan-wizard'
          name: "Flic Scan Wizard"
        }
      if createFlicClearConfig
        @framework.deviceManager.devicesConfig.push {
          class: 'FlicClearConfig'
          id: 'flic-clear-config'
          name: "Flic Clear Configs"
        }



      deviceConfigDef = require('./device-config-schema')
      schema = createDeviceSchema @daemons, deviceConfigDef.FlicButton
      @framework.deviceManager.registerDeviceClass "FlicButton", {
        configDef: schema
        createCallback: (config) =>
          button = new FlicButton(config, @)
          @buttons[button.hwAddress] = button
          if button.daemon is 'none'
            return button
          else
            daemon = @daemons[button.daemon]
            return button unless daemon.connected
            daemon.addFlicButtonConnectionChannel(button)

          return button
        prepareConfig: (config) =>
          config.buttons = createButtons(config.id) if config.buttons.length is 0
          button = @buttons[config.hwAddress]
          if button?
            return config if button.daemon is 'none'
            if button.daemon isnt config.daemon
              throw new Error("Button with hwAddr of #{config.hwAddress} already exists in daemon ")
          else
            console.log 'new button'
          return config

      }
      console.log @daemons
      @framework.deviceManager.registerDeviceClass "FlicScanWizard", {
        configDef: deviceConfigDef.FlicScanWizardButton
        createCallback: (config) =>
          return new FlicScanWizardButton(config, @daemons)

      }
      @framework.deviceManager.registerDeviceClass "FlicClearConfig", {
        configDef: deviceConfigDef.FlicScanWizardButton
        createCallback: (config) =>
          return new FlicClearConfig(config, @daemons, @buttons)

      }
      @framework.deviceManager.on "discover", @discover
      @daemons[key].connect() for key, daemon of @daemons



    discover: =>
      return new Promise (resolve) =>
        createdFlics = Object.keys(@buttons)
        newButtons = {}
        for key, daemon of @daemons
          for id in daemon.bdAddrOfVerifiedButtons when id not in createdFlics
            if not @buttons[id]?
              newButtons[id] = switch
                when newButtons[id]? then null
                else key
        for id, daemonName of newButtons
          console.log daemonName
          latency = if daemonName is null then @config.defaultLatencyMode else @daemons[daemonName].defaultLatencyMode
          config =
            class: "FlicButton"
            hwAddress: id
            connectionOptions:
              latencyMode:  latency
          if daemonName? then config.daemon = daemonName
          console.log config
          @framework.deviceManager.discoveredDevice 'pimatic-flic', "Flic Button #{id}", config
        return resolve()


    destroyButton: (button) =>
      daemon = @daemons[button.daemon]
      return unless daemon?
      daemon.client.removeConnectionChannel(button.listener)
      return





  flicPlugin = new FlicPlugin()

  class FlicScanWizardButton extends env.devices.ButtonsDevice
    constructor: (@config, @daemons) ->
      console.log @config
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

  class FlicClearConfig extends env.devices.ButtonsDevice
    constructor: (@config, @daemons, @buttons) ->

      if @config.id isnt 'flic-clear-config'
        throw new Error("Invalid id")
      @id = @config.id
      @name = @config.name
      console.log @config
      @config.buttons = ({text: daemon.config.name, id: key} for key, daemon of @daemons)
      @config.buttons.push {text: 'All', id: 'all'}

      super @config

    buttonPressed: (id) =>
      console.log id
      return @clean(@daemons[id])



    clean: (daemon) =>
      buttons = (button for key, button of @buttons when button.daemon is daemon.id)
      daemon.removeFlicButtonConnectionChannel(button) for button in buttons
      return new Promise (resolve) ->
        return resolve() if daemon.bdAddrOfVerifiedButtons.length is 0
        ssh = new node_ssh()
        dirPath = __dirname.split('/')
        return ssh.connect({
          host: daemon.config.host
          username: 'pi'
          privateKey: path.join dirPath[0..2].join('/'), '.ssh/id_rsa'}
        ).then =>
          return ssh.execCommand('ls flic').then (result) ->
            console.log result.stdout.includes('flic.sqlite3')
            return result.stdout.includes('flic.sqlite3')
        .then (hasFile) =>
          console.log hasFile
          return no unless hasFile
          return ssh.execCommand('rm -f flic/flic.sqlite3').then (result) ->
            @daemons.bdAddrOfVerifiedButtons = []
            return true
        .then (restart) =>
          return unless restart
          console.log 'restarting'
          return ssh.execCommand('sudo systemctl restart flicd.service').then (result) ->
            console.log('STDOUT: ' + result.stdout)
            console.log('STDERR: ' + result.stderr)
            return
        .then =>
          ssh.dispose()
          return resolve()
        .catch (err) ->
          ssh.dispose()
          return resolve()

  return flicPlugin