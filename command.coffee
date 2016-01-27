colors         = require 'colors'
dashdash      = require 'dashdash'
MeshbluConfig = require 'meshblu-config'
redis         = require 'redis'
Server        = require './server'

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
    {
      names: ['redis-uri', 'r']
      type: 'string'
      help: 'Redis URI (default: redis://localhost:6379)'
      env: 'REDIS_URI'
      default: 'redis://localhost:6379'
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

  getMeshbluConfig: =>
    meshbluConfig = new MeshbluConfig().toJSON()
    return @panic new Error('Missing uuid in meshbluConfig') unless meshbluConfig.uuid?
    meshbluConfig

  panic: (error) =>
    console.error colors.red error.message
    console.error error.stack
    process.exit 1

  run: =>
    {port,redisUri} = @getOptions()
    meshbluConfig = @getMeshbluConfig()

    client = redis.createClient redisUri
    server = new Server {port, client}
    server.run (error) =>
      return @panic error if error?

      {address,port} = server.address()
      console.log "Server listening on #{address}:#{port}"

module.exports = Command
