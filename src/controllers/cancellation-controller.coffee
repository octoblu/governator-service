DeployService = require '../services/deploy-service'
request       = require 'request'
debug         = require('debug')('governator-service:cancellation-controller')

class CancellationController
  constructor: ({ @deployDelay, @deployStateUri, @cluster }) ->
    throw new Error 'deployDelay is required' unless @deployDelay?
    throw new Error 'deployStateUri is required' unless @deployStateUri?
    throw new Error 'cluster is required' unless @cluster?

  create: (request, response) =>
    { etcdDir, dockerUrl } = request.body
    deployService = new DeployService({ client: request.redisClient, @deployDelay })
    deployService.cancel { etcdDir, dockerUrl }, (error) =>
      return response.sendError error if error?
      @_notifyDeployStateService { dockerUrl }, (error) =>
        return response.sendError error if error?
        response.sendStatus 201

  _notifyDeployStateService: ({ dockerUrl }, callback) =>
    [project, tag] = dockerUrl.split(':')
    pieces = project.split('/')

    offset = 0
    offset = 1 if pieces[0] == 'quay.io'

    owner  = pieces[offset]
    repo = pieces[offset + 1]

    options =
      baseUrl: @deployStateUri
      uri: "/deployments/#{owner}/#{repo}/#{tag}/cluster/#{@cluster}/failed"
    debug 'notifying deploy state service', options
    request.put options, (error, response) =>
      return callback error if error?
      return callback new Error 'invalid response from deploy state service' if response.statusCode > 499
      callback null

module.exports = CancellationController
