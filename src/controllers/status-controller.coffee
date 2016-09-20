DeployService = require '../services/deploy-service'

class StatusController
  constructor: ({ @deployDelay }) ->
    throw new Error 'Missing deployDelay' unless @deployDelay?

  show: (request, response) =>
    deployService = new DeployService({ client: request.redisClient, @deployDelay })
    deployService.getStatus (error, result) =>
      return response.sendError error if error?
      response.status(200).send result

module.exports = StatusController
