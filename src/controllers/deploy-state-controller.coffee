_     = require 'lodash'
debug = require('debug')('governator-service:deploy-state-controller')

class DeployStateController
  constructor: ({ @deployService, @requiredClusters }) ->
    throw new Error 'deployService is required' unless @deployService?
    throw new Error 'requiredClusters is required' unless @requiredClusters?

  update: (request, response) =>
    { repo, owner, build, cluster } = request.body
    debug 'update', request.body
    return response.sendStatus(204) unless build?.passing
    return response.sendStatus(204) unless build?.dockerUrl?
    options = {
      etcdDir: "/#{repo}/#{owner}",
      dockerUrl: build.dockerUrl,
      passing: @_isPassing(cluster)
    }
    debug 'update options', options
    @deployService.upsert options, (error) =>
      return response.sendError error if error?
      response.sendStatus 204

  _isPassing: (cluster) =>
    return true if _.isEmpty @requiredClusters
    passing = true
    debug { @requiredClusters }
    _.each @requiredClusters, (key) =>
      return unless passing
      debug 'cluster', { key, cluster: cluster?[key] }
      passing = false unless cluster?[key]?.passing
    return passing

module.exports = DeployStateController
