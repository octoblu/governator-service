DeployController = require './controllers/deploy-controller'
CancellationController = require './controllers/cancellation-controller'

class Router
  constructor: ({client,deployDelay}) ->
    @deployController = new DeployController {client, deployDelay}
    @cancellationController = new CancellationController {client}

  route: (app) =>
    app.post '/deploys', @deployController.create
    app.post '/cancellations', @cancellationController.create

module.exports = Router
