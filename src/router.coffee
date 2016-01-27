DeployController = require './controllers/deploy-controller'

class Router
  constructor: ({client,deployDelay}) ->
    @deployController = new DeployController {client, deployDelay}

  route: (app) =>
    app.post '/deploys', @deployController.create

module.exports = Router
