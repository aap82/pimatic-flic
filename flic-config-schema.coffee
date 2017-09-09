module.exports =
  title: "Flic Plugin Config Options"
  type: "object"
  properties:
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
          verifiedButtons: []
        properties:
          name:
            description: "Unique Name of this daemon"
            type: "string"
            required: yes
            unique: yes
          host:
            description: "Host address for Flic service"
            type: "string"
            required: yes
          port:
            description: "Port number for Flic service"
            type: "number"
            required: yes
          autoReconnect:
            description: "Should the plugin attempt to auto-reconnect to daemon after disconnection?"
            type: "boolean"
            required: yes
          autoReconnectInterval:
            description: "Auto reconnect interval period in seconds"
            type: "number"
            required: yes
          maxRetries:
            description: "Maximum number of retries to auto-reconnect before stopping"
            type: "number"
          verifiedButtons:
            description: "Used to store verified buttons belonging to this daemon"
            type: "array"
            items:
              type: "string"
          id:
            description: "An param-case id will be assigned from name if not provided"
            type: "string"




