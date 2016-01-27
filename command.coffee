dashdash = require 'dashdash'

class Command
  constructor: (@argv) ->
  @OPTIONS: [
    {
      names: ['help', 'h']
      type: 'bool'
      help: 'Print this help and exit.'
    },
    {
      names: ['port', 'p']
      type: 'integer'
      help: 'Port for the server to listen on'
      env: 'PORT'
      default: 80
    },
  ]

  getOptions: =>
    parser = dashdash.createParser {options: Command.OPTIONS}
    options = parser.parse @argv
    if options.help
      help = parser.help({includeEnv: true}).trimRight()
      console.log """
        usage: node command.js [OPTIONS]\n
        options:\n
        #{help}"""
      process.exit 0
    return options

  panic: (error) =>
    console.error error.stack
    process.exit 1

  run: =>
    {port} = @getOptions()
    server = new Server {port}
    server.run (error) =>
      return @panic error if error?

      {address,port} = server.address()
      console.log "Server listening on #{address}:#{port}"

module.exports = Command
