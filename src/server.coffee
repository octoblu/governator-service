_                  = require 'lodash'
enableDestroy      = require 'server-destroy'
octobluExpress     = require 'express-octoblu'
meshbluAuthDevice  = require 'express-meshblu-auth-device'

DeployService      = require './services/deploy-service'
Router             = require './router'

class Server
  constructor: (options) ->
    { @port, @logFn, @meshbluConfig, @disableLogging } = options
    { @client, @deployDelay, @redisQueue,  } = options
    { @requiredClusters, @octobluRaven } = options
    { @cluster, @deployStateUri } = options
    throw new Error('client is required') unless @client?
    throw new Error('deployDelay is required') unless @deployDelay?
    throw new Error('redisQueue is required') unless @redisQueue?
    throw new Error('requiredClusters is required') unless @requiredClusters?
    throw new Error('deployStateUri is required') unless @deployStateUri?
    throw new Error('cluster is required') unless @cluster?

  address: =>
    @server.address()

  run: (callback) =>
    app = octobluExpress({ @octobluRaven, @disableLogging, @logFn })

    app.use meshbluAuthDevice @meshbluConfig

    deployService = new DeployService { @client, @deployDelay, @redisQueue }

    router = new Router { deployService, @requiredClusters, @deployStateUri, @cluster }
    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: =>
    @server.destroy()

module.exports = Server
