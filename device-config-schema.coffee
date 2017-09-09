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
      bdAddr:
        description: "The mac address of the flic button"
        type: "string"
        required: yes
      upDown:
        description: "Listen for Button Down and Up Events"
        type: "boolean"
        default: no
      maxTimeDiff:
        description:"The maximum allowed difference between button push and receive time."
        type: "number"
        required: yes
        default: 3
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
                description: 'Button Id'
                type: 'string'
                default: ''
              text:
                description: 'Button Id'
                type: 'string'
                default: ''
