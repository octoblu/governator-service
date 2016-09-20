_             = require 'lodash'
colors        = require 'colors'
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
    },
    {
      names: ['cluster']
      type: 'string',
      help: 'The current cluster',
      env: 'CLUSTER'
    },
    {
      names: ['redis-uri']
      type: 'string'
      help: 'Redis URI'
      env: 'REDIS_URI'
    },
    {
      names: ['redis-queue']
      type: 'string'
      help: 'Redis Queue'
      env: 'REDIS_QUEUE'
    },
    {
      names: ['deploy-delay']
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
    {
      names: ['max-connections']
      type: 'integer'
      help: 'Max number of redis connections'
      env: 'MAX_CONNECTIONS',
      default: 10
    },
    {
      names: ['min-connections']
      type: 'integer'
      help: 'Min number of redis connections'
      env: 'MIN_CONNECTIONS',
      default: 1
    },
    {
      names: ['idle-timeout']
      type: 'integer'
      help: 'Redis pool idle timeout in milliseconds'
      env: 'IDLE_TIMEOUT_MILLIS',
      default: 60000
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
      max_connections,
      min_connections,
      idle_timeout_millis,
    } = @getOptions()
    meshbluConfig = @getMeshbluConfig()

    server = new Server {
      port,
      cluster,
      meshbluConfig,
      redisUri: redis_uri,
      namespace: redis_queue,
      maxConnections: max_connections,
      minConnections: min_connections,
      idleTimeoutMillis: idle_timeout_millis,
      requiredClusters: required_clusters.split(',').map(_.trim),
      deployDelay: deploy_delay,
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
