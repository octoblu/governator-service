_                 = require 'lodash'
express           = require 'express'
morgan            = require 'morgan'
errorHandler      = require 'errorhandler'
bodyParser        = require 'body-parser'
meshbluAuthDevice = require 'express-meshblu-auth-device'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
Router            = require './router'

class Server
  constructor: ({@port, @meshbluConfig, @disableLogging, @client, @deployDelay, @redisQueue}) ->
    throw new Error('client is required') unless @client?
    throw new Error('deployDelay is required') unless @deployDelay?
    throw new Error('redisQueue is required') unless @redisQueue?

  address: =>
    @server.address()

  run: (callback) =>
    app = express()
    app.use meshbluHealthcheck()
    app.use morgan 'dev', immediate: false unless @disableLogging
    app.use errorHandler()
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

    router = new Router {@client, @deployDelay, @redisQueue}
    router.route app

    @server = app.listen @port, callback

  stop: (callback) =>
    @server.close callback

module.exports = Server
