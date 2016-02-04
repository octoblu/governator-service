DeployController = require './controllers/deploy-controller'
CancellationController = require './controllers/cancellation-controller'

class Router
  constructor: ({client, deployDelay}) ->
    throw new Error('client is required') unless client?
    throw new Error('deployDelay is required') unless deployDelay?

    @deployController = new DeployController {client, deployDelay}
    @cancellationController = new CancellationController {client}

  route: (app) =>
    app.post '/deploys', @deployController.create
    app.post '/cancellations', @cancellationController.create

module.exports = Router
