DeployStateController  = require './controllers/deploy-state-controller'
DeploymentsController  = require './controllers/deployments-controller'
CancellationController = require './controllers/cancellation-controller'
SchedulesController    = require './controllers/schedules-controller'
StatusController       = require './controllers/status-controller'

class Router
  constructor: ({ deployService, requiredClusters, deployStateUri, cluster }) ->
    throw new Error('deployService is required') unless deployService?
    throw new Error('requiredClusters is required') unless requiredClusters?
    throw new Error('deployStateUri is required') unless deployStateUri?
    throw new Error('cluster is required') unless cluster?

    @deployStateController = new DeployStateController { deployService, requiredClusters }
    @deploymentsController = new DeploymentsController { deployService }
    @cancellationController = new CancellationController { deployService, deployStateUri, cluster }
    @schedulesController = new SchedulesController  { deployService }
    @statusController = new StatusController  { deployService }

  route: (app) =>
    app.put  '/v2/deployments', @deployStateController.update
    app.post '/deployments', @deploymentsController.create
    app.post '/cancellations', @cancellationController.create
    app.post '/schedules', @schedulesController.create
    app.get  '/status', @statusController.show

module.exports = Router
