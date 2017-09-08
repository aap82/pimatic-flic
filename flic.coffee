module.exports = (env) ->
  _ = require './utils'
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  paramCase = require 'param-case'
  {FlicConnectionChannel} = require("./lib/fliclibNodeJs")
  FlicDaemon = require('./flic-daemon')(env)
  FlicButton = require('./device/flic-button')(env)
  {FlicScanWizardButton, flicScanWizardConfig} = require('./device/flic-scanwizard')(env)
  FlicButtonPredicateProvider = require('./predicates/flic-predicates')(env)

  checkConfig = (config) ->
    ids = []
    hosts = []
    for d in config.daemons
      assert d.name?
      d.id = paramCase(d.name)
      if d.id in ids
        throw new Error "Duplicate daemon id #{d.id}"
      if d.host in hosts
        throw new Error "Duplicate host address #{d.host}"
      ids.push d.id
      hosts.push d.host
    return config

  class FlicPlugin extends env.plugins.Plugin
    prepareConfig: (config) -> return checkConfig(config)
    getDeviceByAddr: (bdAddr) =>
      for id, btn of @devices when btn.bdAddr is bdAddr
        return btn
      return null

    init: (app, @framework, @config) =>
      return unless @config.daemons.length > 0
      @devices = {}
      @channels = {}
      @daemons = {}
      @daemons[d.id] = new FlicDaemon(d, @) for d in @config.daemons
      unless @framework.deviceManager.isDeviceInConfig('flic-scan-wizard')
        @framework.deviceManager.addDeviceToConfig flicScanWizardConfig


      deviceConfigDef = require('./device-config-schema')
      deviceConfigDef.FlicButton.properties.daemonID.enum = _.keys(@daemons)

      @framework.deviceManager.registerDeviceClass "FlicButton", {
        configDef: deviceConfigDef.FlicButton
        createCallback: @createButtonCallback(FlicButton)
      }
      @framework.deviceManager.registerDeviceClass "FlicScanWizard", {
        configDef: deviceConfigDef.FlicScanWizardButton
        createCallback: ((config) => return new FlicScanWizardButton(config, @daemons))
      }

      @framework.ruleManager.addPredicateProvider(new FlicButtonPredicateProvider(@framework))
      @framework.deviceManager.on "deviceRemoved", @deviceRemoved
      @framework.deviceManager.on "discover", @discover


    createButtonCallback: (classType) =>
      return (config) =>
        {id, bdAddr, daemonID} = config
        if daemonID not in _.keys(@daemons)
          throw new Error "#{daemonID} is an unknown daemon client"
        if bdAddr not in @daemons[daemonID].verifiedButtons
          throw new Error "bdAddr #{bdAddr} not verified on #{@name} daemon"

        con = @daemons[daemonID].connectButton(bdAddr, cc)
        button = new classType(config, @, cc)
        @devices[id] = button
        @channels[bdAddr] = cc
        return button

        throw new Error "#{daemonID} is an unknown daemon client"
        if bdAddr not in @daemons[daemonID].verifiedButtons
          throw new Error "bdAddr #{bdAddr} not verified on #{@name} daemon"

        @channels[bdAddr] = new FlicConnectionChannel(bdAddr)


    deviceRemoved: (device) =>
      return unless device.config.class is 'FlicButton'
      console.log 'removed'
      @daemons[device.daemonID]?.disconnectButton(device.bdAddr)
      delete @devices[device.id]
      delete @channels[device.bdAddr]
      return

    newVerifiedFlic: (daemonID, bdAddr) =>
      device = @getDeviceByAddr(bdAddr)
      daemon.disconnectButton(bdAddr) for id, daemon of @daemons when id isnt daemonID
      if device?
        device.daemonID = daemonID
        @framework.deviceManager.recreateDevice(device, device.config)
      return
    discover: =>
      return new Promise (resolve) =>
        createdFlics = (btn.bdAddr for key, btn of @devices)
        for key, d of @daemons
          for bdAddr in d.discover(createdFlics)
            config = {
              daemonID: d.id
              class: "FlicButton"
              bdAddr
            }
            @framework.deviceManager.discoveredDevice 'pimatic-flic', "#{d.name} daemon: #{bdAddr}", config
        return resolve()

    logInfo: (str) -> env.logger.info "Flig Plugin: #{str}"
    logWarn: (str) -> env.logger.warn "Flig Plugin: #{str}"
    logDebug: (str) -> env.logger.debug "Flig Plugin: #{str}"
    logError: (str) -> env.logger.error "Flic Plugin: #{str}"
    connError: ({id, host, port}, error) =>
      if error? and error.code is 'ECONNREFUSED'
        env.logger.error "Flic: daemon #{id} connection failed to #{host}:#{port}"
      else
        env.logger.error "Flic: daemon #{id} connection error: #{error}"

  flicPlugin = new FlicPlugin()
  return flicPlugin