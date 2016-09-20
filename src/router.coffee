DeployStateController  = require './controllers/deploy-state-controller'
DeploymentsController  = require './controllers/deployments-controller'
CancellationController = require './controllers/cancellation-controller'
SchedulesController    = require './controllers/schedules-controller'
StatusController       = require './controllers/status-controller'

class Router
  constructor: ({ requiredClusters, deployStateUri, cluster, deployDelay }) ->
    throw new Error('requiredClusters is required') unless requiredClusters?
    throw new Error('deployStateUri is required') unless deployStateUri?
    throw new Error('cluster is required') unless cluster?
    throw new Error('deployDelay is required') unless deployDelay?

    @deployStateController = new DeployStateController { deployDelay, requiredClusters }
    @deploymentsController = new DeploymentsController { deployDelay }
    @cancellationController = new CancellationController { deployDelay, deployStateUri, cluster }
    @schedulesController = new SchedulesController  { deployDelay }
    @statusController = new StatusController  { deployDelay }

  route: (app) =>
    app.put  '/v2/deployments', @deployStateController.update
    app.post '/deployments', @deploymentsController.create
    app.post '/cancellations', @cancellationController.create
    app.post '/schedules', @schedulesController.create
    app.get  '/status', @statusController.show

module.exports = Router
