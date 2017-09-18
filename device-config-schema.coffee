module.exports =
  title: "Pimatic Flic Device Config Schemas"
  FlicButton:
    title: "Flic Button"
    type: "object"
    properties:
      daemonID:
        description:  "Daemon this Button is connected to"
        type: "string"
        default: 'none'
        required: yes
      upDown:
        description: "Listen for Button Down and Up Events"
        type: "boolean"
        default: no
      maxTimeDiff:
        description:"The maximum allowed difference between button push and receive time (in seconds)"
        type: "number"
        required: yes
        default: 3
      bdAddr:
        description: "The mac address of the flic button"
        type: "string"
        required: yes
  FlicScanWizardButton:
      title: "FlicScanWizard"
      type: "object"
      properties:
        buttons:
          description: "Flic Daemons to Scan"
          type: "array"
          default: []
          format: "table"
          items:
            type: "object"
            properties:
              id:
                description: 'The id of the flic daemon client'
                type: 'string'
              text:
                description: 'The name of the flic daemon client'
                type: 'string'
