DeployService = require '../services/deploy-service'

class SchedulesController
  constructor: ({ @deployDelay }) ->
    throw new Error 'Missing deployDelay' unless @deployDelay?

  create: (request, response) =>
    { etcdDir, dockerUrl, deployAt } = request.body

    unless etcdDir && dockerUrl
      return response.status(422).send error: "Missing etcdDir or dockerUrl, received: '#{JSON.stringify request.body}'"

    deployService = new DeployService({ client: request.redisClient, @deployDelay })
    deployService.exists { etcdDir, dockerUrl }, (error, exists) =>
      return response.sendError error if error?
      return response.sendStatus 404 unless exists
      deployService.schedule { etcdDir, dockerUrl, deployAt }, (error) =>
        return response.sendError error if error?
        response.sendStatus 201

module.exports = SchedulesController
