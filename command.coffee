_             = require 'lodash'
colors        = require 'colors'
Redis         = require 'ioredis'
dashdash      = require 'dashdash'
MeshbluConfig = require 'meshblu-config'

Server        = require './server'
packageJSON   = require './package.json'

class Command
  constructor: (@argv) ->

  @OPTIONS: [
    {
      names: ['help', 'h']
      type: 'bool'
      help: 'Print this help and exit.'
    },
    {
      names: ['version', 'v']
      type: 'bool'
      help: 'Print the version and exit.'
    },
    {
      names: ['port', 'p']
      type: 'integer'
      help: 'Port for the server to listen on'
      env: 'PORT'
      default: 80
    },
    {
      names: ['required-clusters']
      type: 'string'
      help: 'The required clusters in other to run. Separated by commas.'
      env: 'REQUIRED_CLUSTERS'
      default: 'minor'
    },
    {
      names: ['cluster', 'c']
      type: 'string',
      help: 'The current cluster',
      env: 'CLUSTER'
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
      env: 'REDIS_QUEUE'
      default: 'redis://localhost:6379'
    },
    {
      names: ['deploy-delay', 'd']
      type: 'integer'
      help: 'Delay during which the deploy may be cancelled (in seconds)'
      env: 'DEPLOY_DELAY'
      default: 10 * 60
    },
    {
      names: ['deploy-state-uri']
      type: 'string'
      help: 'Deploy State URI. Should contain basic authentication.'
      env: 'DEPLOY_STATE_URI'
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
    if options.version
      console.log packageJSON.version
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
    {
      port,
      required_clusters,
      cluster,
      redis_uri,
      redis_queue,
      deploy_delay,
      deploy_state_uri,
    } = @getOptions()
    meshbluConfig = @getMeshbluConfig()

    client = new Redis redis_uri, dropBufferSupport: true
    server = new Server {
      port,
      client,
      cluster,
      meshbluConfig,
      requiredClusters: required_clusters.split(',').map(_.trim),
      deployDelay: deploy_delay,
      redisQueue: redis_queue,
      deployStateUri: deploy_state_uri,
    }
    server.run (error) =>
      return @panic error if error?

      {address,port} = server.address()
      console.log "Governator service listing on port #{port}"

    process.on 'SIGTERM', =>
      console.log 'SIGTERM caught, exiting'
      server?.stop =>
        process.exit 0

      setTimeout =>
        console.log 'Server did not stop in time, exiting 0 manually'
        server?.destroy()
        process.exit 0
      , 5000

module.exports = Command
