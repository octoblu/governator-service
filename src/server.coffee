express           = require 'express'
morgan            = require 'morgan'
errorHandler      = require 'errorhandler'
bodyParser        = require 'body-parser'
meshbluAuthDevice = require 'express-meshblu-auth-device'
Router  = require './router'

class Server
  constructor: ({@port,@meshbluConfig,@disableLogging,@client,@deployDelay}) ->

  run: (callback) =>
    app = express()
    app.use morgan 'dev', immediate: false unless @disableLogging
    app.use errorHandler()
    app.use meshbluAuthDevice(@meshbluConfig)
    app.use bodyParser.urlencoded limit: '50mb', extended : true
    app.use bodyParser.json limit : '50mb'

    router = new Router {@client, @deployDelay}
    router.route app

    @server = app.listen @port, callback

  stop: (callback) =>
    @server.close callback

module.exports = Server
