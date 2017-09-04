
module.exports =
  title: "Flic Plugin Config Options"
  type: "object"
  properties:
    debug:
      description: "Launch plugin in debug mode"
      type: "boolean"
      default: true
    clean:
      description:
          """
      Enabling will execute ssh command to remove the flic button database and restart the service.
      Assumes the login is pi, the path to file is ~/flic/flic.flic.sqlite3 and service name is flicd.service
                """
      type: "boolean"
      default: false
    defaultLatencyMode:
      description: "Default latency for connection to buttons"
      type: "string"
      default: "HighLatency"
      enum: ["HighLatency", "NormalLatency", "LowLatency"]
    daemons:
      description: "List of Flic Daemons"
      type: "array"
      format: "table"
      default: []
      items:
        description: "Settings for Flic Daemon"
        type: "object"
        default:
          name: ''
          host: 'localhost'
          port: 5551
          autoReconnect: yes
          autoReconnectInterval: 30
          maxRetries: 1000
        properties:
          name:
            description: "Unique Name of this daemon"
            type: "string"
            required: yes
          host:
            description: "Host address for Flic service"
            type: "string"
            default: "localhost"
            required: yes
          port:
            description: "Port number for Flic service"
            type: "number"
            default: 5551
            required: yes
          defaultLatencyMode:
            description: "Default latency for connection to buttons"
            type: "string"
            default: ""
            enum: ["", "HighLatency", "NormalLatency", "LowLatency"]
          autoReconnect:
            description: "Auto reconnect to daemon after disconnect."
            type: "boolean"
            default: true
            required: yes
          autoReconnectInterval:
            description: "Auto reconnect interval period"
            type: "number"
            default: 60
            required: yes
          maxRetries:
            description: "Maximum number of retries to connect"
            type: "number"
            default: 1000
