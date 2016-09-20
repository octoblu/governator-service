_     = require 'lodash'
async = require 'async'
debug = require('debug')('governator-service:deploy-service')

class DeployService
  constructor: ({ @client, @deployDelay }) ->
    throw new Error('client is required') unless @client?
    throw new Error('deployDelay is required') unless @deployDelay?
    @TTL = 7 * 24 * 60 * 60 # 7 days

  cancel: ({ etcdDir, dockerUrl }, callback) =>
    debug 'cancellation', {etcdDir, dockerUrl}
    metadataLocation = @_getMetadataLocation { etcdDir, dockerUrl }
    @client.hset metadataLocation, 'cancellation', Date.now(), (error) =>
      debug 'cancel hset', { error, metadataLocation }
      return callback error if error?
      @client.expire metadataLocation, @TTL, callback

  create: ({ etcdDir, dockerUrl, metadata }, callback) =>
    debug 'create deployment', { etcdDir, dockerUrl }
    deployTime = (Date.now() / 1000) + @deployDelay
    metadata ?= JSON.stringify { etcdDir, dockerUrl }
    metadataLocation = @_getMetadataLocation { etcdDir, dockerUrl }
    @client.del metadataLocation, (error) =>
      debug 'create deleted', { error, metadataLocation }
      return callback error if error?
      @client.hset metadataLocation, 'request:metadata', metadata, (error) =>
        debug 'create hset', { error, metadataLocation }
        return callback error if error?
        @client.expire metadataLocation, @TTL, (error) =>
          debug 'create expire', { error, metadataLocation }
          return callback error if error?
          @client.zadd 'governator:deploys', Math.floor(deployTime), metadataLocation, callback

  schedule: ({ etcdDir, dockerUrl, deployAt }, callback) =>
    debug 'schedule', { etcdDir, dockerUrl, deployAt }
    metadataLocation = @_getMetadataLocation { etcdDir, dockerUrl }
    @client.zadd 'governator:deploys', deployAt, metadataLocation, callback

  getStatus: (callback) =>
    @client.zrange 'governator:deploys', 0, -1, (error, data) =>
      return callback error if error?
      async.map data, @_getData, (error, loadedData) =>
        return callback error if error?
        callback null, _.keyBy loadedData, 'key'

  exists: ({ etcdDir, dockerUrl }, callback) =>
    metadataLocation = @_getMetadataLocation { etcdDir, dockerUrl }
    @client.exists metadataLocation, callback

  _getMetadataLocation: ({ etcdDir, dockerUrl }) =>
    return "governator:#{etcdDir}:#{dockerUrl}"

  _getData: (key, callback) =>
    @client.zscore 'governator:deploys', key, (error, score) =>
      return callback error if error?

      status = 'pending'
      @client.hexists key, 'cancellation', (error, exists) =>
        status = 'cancelled' if exists

        callback null, {
          key: key
          deployAt: parseInt(score)
          status: status
        }

module.exports = DeployService
