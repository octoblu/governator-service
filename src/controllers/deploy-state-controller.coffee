_     = require 'lodash'
debug = require('debug')('governator-service:deploy-state-controller')

class DeployStateController
  constructor: ({ @deployService, @requiredClusters }) ->
    throw new Error 'deployService is required' unless @deployService?
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
    @deployService.exists options, (error, exists) =>
      return response.sendError error if error?
      return @_handleCancel cluster, options, response if exists
      @_handleCreate cluster, options, response

  _handleCancel: (cluster, options, response) =>
    return response.sendStatus(208) if @_isPassing cluster
    @deployService.cancel options, (error) =>
      return response.sendError error if error?
      response.sendStatus(204)

  _handleCreate: (cluster, options, response) =>
    return response.sendStatus(204) unless @_isPassing cluster
    @deployService.create options, (error) =>
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
