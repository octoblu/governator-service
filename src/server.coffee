_                  = require 'lodash'
express            = require 'express'
morgan             = require 'morgan'
compression        = require 'compression'
bodyParser         = require 'body-parser'
OctobluRaven       = require 'octoblu-raven'
enableDestroy      = require 'server-destroy'
sendError          = require 'express-send-error'
expressVersion     = require 'express-package-version'
meshbluAuthDevice  = require 'express-meshblu-auth-device'
meshbluHealthcheck = require 'express-meshblu-healthcheck'

DeployService      = require './services/deploy-service'
Router             = require './router'

class Server
  constructor: (options) ->
    { @port, @meshbluConfig, @disableLogging } = options
    { @client, @deployDelay, @redisQueue,  } = options
    { @requiredClusters, @octobluRaven } = options
    throw new Error('client is required') unless @client?
    throw new Error('deployDelay is required') unless @deployDelay?
    throw new Error('redisQueue is required') unless @redisQueue?
    throw new Error('requiredClusters is required') unless @requiredClusters?
    @octobluRaven ?= new OctobluRaven

  address: =>
    @server.address()

  run: (callback) =>
    app = express()
    app.use @octobluRaven.express().handleErrors()
    app.use sendError()
    app.use meshbluHealthcheck()
    app.use compression()
    app.use expressVersion({format: '{"version": "%s"}'})
    skip = (request, response) =>
      return response.statusCode < 400
    app.use morgan 'dev', { immediate: false, skip } unless @disableLogging
    app.use meshbluAuthDevice(@meshbluConfig)
    app.use bodyParser.urlencoded limit: '50mb', extended : true
    app.use bodyParser.json limit : '50mb'
    app.use (request, response, next) =>
      response.sendError = (error) =>
        console.error error.stack
        code = 500
        code = error.code if _.isNumber error.code
        return response.sendStatus code unless error.message?
        return response.status(code).send error.message
      next()

    deployService = new DeployService { @client, @deployDelay, @redisQueue }
    router = new Router { deployService, @requiredClusters }
    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: =>
    @server.destroy()

module.exports = Server
