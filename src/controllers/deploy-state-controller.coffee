_             = require 'lodash'
DeployService = require '../services/deploy-service'
debug         = require('debug')('governator-service:deploy-state-controller')

class DeployStateController
  constructor: ({ @deployDelay, @requiredClusters }) ->
    throw new Error 'Missing deployDelay' unless @deployDelay?
    throw new Error 'requiredClusters is required' unless @requiredClusters?

  update: (request, response) =>
    { repo, owner, build, cluster } = request.body
    debug 'update', request.body
    return response.sendStatus(406) unless build?.passing
    return response.sendStatus(422) unless build?.dockerUrl?
    options = {
      etcdDir: "/#{owner}/#{repo}",
      dockerUrl: build.dockerUrl,
    }
    debug 'update options', options
    deployService = new DeployService({ client: request.redisClient, @deployDelay })
    deployService.exists options, (error, exists) =>
      return response.sendError error if error?
      return @_handleCancel deployService, cluster, options, response if exists
      @_handleCreate deployService, cluster, options, response

  _handleCancel: (deployService, cluster, options, response) =>
    return response.sendStatus(208) if @_isPassing cluster
    deployService.cancel options, (error) =>
      return response.sendError error if error?
      response.sendStatus(204)

  _handleCreate: (deployService, cluster, options, response) =>
    deployService.create options, (error) =>
      return response.sendError error if error?
      response.sendStatus(201)

  _isPassing: (cluster) =>
    return true if _.isEmpty @requiredClusters
    passing = true
    debug { @requiredClusters }
    _.each @requiredClusters, (key) =>
      return unless passing
      debug 'cluster', { key, cluster: cluster?[key] }
      return unless cluster?[key]?
      passing = false unless cluster?[key]?.passing
    return passing

module.exports = DeployStateController
