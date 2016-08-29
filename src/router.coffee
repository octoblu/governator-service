DeploymentsController  = require './controllers/deployments-controller'
CancellationController = require './controllers/cancellation-controller'
SchedulesController    = require './controllers/schedules-controller'
StatusController       = require './controllers/status-controller'

class Router
  constructor: ({ deployService }) ->
    throw new Error('deployService is required') unless deployService?

    @deploymentsController = new DeploymentsController { deployService }
    @cancellationController = new CancellationController { deployService }
    @schedulesController = new SchedulesController  { deployService }
    @statusController = new StatusController  { deployService }

  route: (app) =>
    app.post '/deployments', @deploymentsController.create
    app.post '/cancellations', @cancellationController.create
    app.post '/schedules', @schedulesController.create
    app.get '/status', @statusController.show

module.exports = Router
