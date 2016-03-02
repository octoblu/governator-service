DeploymentsController = require './controllers/deployments-controller'
CancellationController = require './controllers/cancellation-controller'
StatusController = require './controllers/status-controller'

class Router
  constructor: ({client, deployDelay, redisQueue}) ->
    throw new Error('client is required') unless client?
    throw new Error('deployDelay is required') unless deployDelay?
    throw new Error('redisQueue is required') unless redisQueue?

    @deploymentsController = new DeploymentsController {client, deployDelay, redisQueue}
    @cancellationController = new CancellationController {client}
    @statusController = new StatusController {client, redisQueue}

  route: (app) =>
    app.post '/deployments', @deploymentsController.create
    app.post '/cancellations', @cancellationController.create
    app.get '/status', @statusController.show

module.exports = Router
