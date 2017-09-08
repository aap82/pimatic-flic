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
          buttons: []
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
            description: "Auto reconnect to daemon after disconnect."
            type: "boolean"
            required: yes
          autoReconnectInterval:
            description: "Auto reconnect interval period in seconds"
            type: "number"
            required: yes
          maxRetries:
            description: "Maximum number of retries to connect"
            type: "number"
          verifiedButtons:
            description: "This will be used to store buttons belonging to daemon"
            type: "array"
            items:
              type: "string"
          id:
            description: "An param-case id will be assigned from name if not provided"
            type: "string"




