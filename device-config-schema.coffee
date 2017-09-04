module.exports =
  title: "Pimatic Flic Device Config Schemas"
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


  FlicButton:
    title: "Flic Button"
    type: "object"
    extensions: ["xAttributeOptions"]
    properties:
      daemon:
        description:  "Daemon this Button is connected to"
        type: "string"
        default: 'none'
        required: yes
        enum: ['']
      hwAddress:
        description: "The mac address of the flic button"
        type: "string"
        required: yes
      connectionOptions:
        description: "Connection options for flic button"
        type: "object"
        default:
          latencyMode: "NormalLatency"
        properties:
          latencyMode:
            required: yes
            description: "Latency Mode for connection channel"
            type: "string"
            default: "NormalLatency"
            enum: ["HighLatency", "NormalLatency", "LowLatency"]
      maxTimeDiff:
        description:"The maximum allowed difference between button push and receive time."
        type: "number"
        required: yes
        default: 3
      buttons:
        description: "Buttons to display"
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          properties:
#            clickType:
#              description: "Press Type"
#              type: "string"
            id:
              description: 'Button Id'
              type: 'string'
              default: ''
            text:
              description: 'Button Id'
              type: 'string'
              default: ''
            include:
              description: "Listen for this Press Type"
              type: "boolean"
            hidden:
              type: "boolean"





#
#
#clickTypes:
#  description: "The flic press types available"
#  format: "table"
#  type: "object"
#  default:
#    ButtonDown: yes
#    ButtonUp: yes
#    ButtonClick: yes
#    ButtonSingleClick: yes
#    ButtonDoubleClick: yes
#    ButtonHold: yes
#  properties:
#    ButtonDown:
#      description: "On Button Down"
#      type: "boolean"
#      default: yes
#    ButtonUp:
#      description: "On Button Up"
#      type: "boolean"
#      default: yes
#    ButtonClick:
#      description: "On Button Click"
#      type: "boolean"
#      default: yes
#    ButtonSingleClick:
#      description: "On Button SingleClick"
#      type: "boolean"
#      default: yes
#    ButtonDoubleClick:
#      description: "On Button DoubleClick"
#      type: "boolean"
#      default: yes
#    ButtonHold:
#      description: "On Button Hold"
#      type: "boolean"
#      default: yes