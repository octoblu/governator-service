debug = require('debug')('governator-service:cancellation-controller')

class CancellationController
  constructor: ({ @deployService }) ->
    throw new Error 'deployService is required' unless @deployService?

  create: (request, response) =>
    { etcdDir, dockerUrl } = request.body
    @deployService.cancel { etcdDir, dockerUrl }, (error) =>
      return response.sendError error if error?
      response.sendStatus 201

module.exports = CancellationController
