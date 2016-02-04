DeployController = require './controllers/deploy-controller'
CancellationController = require './controllers/cancellation-controller'

class Router
  constructor: ({client, deployDelay, redisQueue}) ->
    throw new Error('client is required') unless client?
    throw new Error('deployDelay is required') unless deployDelay?
    throw new Error('redisQueue is required') unless redisQueue?

    @deployController = new DeployController {client, deployDelay, redisQueue}
    @cancellationController = new CancellationController {client}

  route: (app) =>
    app.post '/deploys', @deployController.create
    app.post '/cancellations', @cancellationController.create

module.exports = Router
