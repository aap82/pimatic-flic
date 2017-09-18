module.exports = (env) ->
  Promise = env.require 'bluebird'
  flicScanWizardConfig =
    id: 'flic-scan-wizard'
    name: 'Flic Scan Wizard'
    class: 'FlicScanWizard'

  class FlicScanWizardButton extends env.devices.Device
    actions:
      buttonPressed:
        params:
          buttonId:
            type: "string"
        description: "Press a button"

    template: "buttons"
    constructor: (@config, @daemons) ->
      if @config.id isnt 'flic-scan-wizard'
        throw new Error("Invalid id")
      @id = @config.id
      @name = @config.name
      @config.buttons = ({text: daemon.config.name, id} for id, daemon of @daemons)
      super

    buttonPressed: (id) =>
      return unless @daemons[id]?
      @daemons[id].scan()
      return Promise.resolve()

    destroy: ->
      super()

  return {FlicScanWizardButton, flicScanWizardConfig}