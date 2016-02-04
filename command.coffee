colors        = require 'colors'
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
    {
      names: ['redis-queue', 'q']
      type: 'string'
      help: 'Redis Queue (default: governator:request)'
      env: 'REDIS_URI'
      default: 'redis://localhost:6379'
    },
    {
      names: ['deploy-delay', 'd']
      type: 'integer'
      help: 'Delay during which the deploy may be cancelled (in seconds)'
      env: 'DEPLOY_DELAY'
      default: 10 * 60
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
    {port,redis_uri,redis_queue,deploy_delay} = @getOptions()
    meshbluConfig = @getMeshbluConfig()

    client = redis.createClient redis_uri
    server = new Server {port, client, meshbluConfig, deployDelay: deploy_delay, redisQueue: redis_queue}
    server.run (error) =>
      return @panic error if error?

      {address,port} = server.address()
      console.log "Server listening on #{address}:#{port}"

module.exports = Command
