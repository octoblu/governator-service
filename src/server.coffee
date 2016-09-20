_                  = require 'lodash'
enableDestroy      = require 'server-destroy'
octobluExpress     = require 'express-octoblu'
meshbluAuthDevice  = require 'express-meshblu-auth-device'
RedisPooledClient  = require 'express-redis-pooled-client'
Router             = require './router'

class Server
  constructor: (options) ->
    { @port, @logFn, @meshbluConfig, @disableLogging } = options
    { @redisUri, @namespace, @maxConnections, @minConnections, @idleTimeoutMillis } = options
    { @deployDelay, @octobluRaven } = options
    { @requiredClusters, @cluster, @deployStateUri } = options
    throw new Error('redisUri is required') unless @redisUri?
    throw new Error('namespace is required') unless @namespace?
    throw new Error('maxConnections is required') unless @maxConnections?
    throw new Error('deployDelay is required') unless @deployDelay?
    throw new Error('requiredClusters is required') unless @requiredClusters?
    throw new Error('deployStateUri is required') unless @deployStateUri?
    throw new Error('cluster is required') unless @cluster?

  address: =>
    @server.address()

  run: (callback) =>
    app = octobluExpress({ @octobluRaven, @disableLogging, @logFn })

    app.use meshbluAuthDevice @meshbluConfig

    redisPooledClient = new RedisPooledClient {
      @redisUri,
      @namespace,
      @maxConnections,
      @minConnections,
    }

    app.use redisPooledClient.middleware

    router = new Router { @deployDelay, @requiredClusters, @deployStateUri, @cluster }
    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: =>
    @server.destroy()

module.exports = Server
