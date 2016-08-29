_     = require 'lodash'
async = require 'async'
debug = require('debug')('governator-service:deploy-service')

class DeployService
  constructor: ({ @client, @deployDelay, @redisQueue }) ->
    throw new Error('client is required') unless @client?
    throw new Error('deployDelay is required') unless @deployDelay?
    throw new Error('redisQueue is required') unless @redisQueue?

  cancel: ({ etcdDir, dockerUrl }, callback) =>
    debug 'cancellation', {etcdDir, dockerUrl}
    metadataLocation = "governator:#{etcdDir}:#{dockerUrl}"
    @client.hset metadataLocation, 'cancellation', Date.now(), (error) =>
      return callback error if error?
      @client.expire metadataLocation, 24*60*60, callback

  create: ({ etcdDir, dockerUrl, metadata }, callback) =>
    debug 'deployment', { etcdDir, dockerUrl }
    deployTime = (Date.now() / 1000) + @deployDelay

    metadataLocation = "governator:#{etcdDir}:#{dockerUrl}"
    @client.del metadataLocation, (error) =>
      return callback error if error?
      @client.hset metadataLocation, 'request:metadata', metadata, (error) =>
        return callback error if error?
        @client.expire metadataLocation, 24*60*60, (error) =>
          return callback error if error?
          @client.zadd @redisQueue, Math.floor(deployTime), metadataLocation, callback

  schedule: ({ etcdDir, dockerUrl, deployAt, metadata }, callback) =>
    debug 'schedule', { etcdDir, dockerUrl, deployAt }
    metadataLocation = "governator:#{etcdDir}:#{dockerUrl}"
    @client.exists metadataLocation, (error, exists) =>
      return callback error if error?
      return callback { code: 404 } unless exists
      @client.zadd @redisQueue, deployAt, metadataLocation, callback

  getStatus: (callback) =>
    @client.zrange @redisQueue, 0, -1, (error, data) =>
      return callback error if error?
      async.map data, @_getData, (error, loadedData) =>
        return callback error if error?
        callback null, _.keyBy loadedData, 'key'

  _getData: (key, callback) =>
    @client.zscore @redisQueue, key, (error, score) =>
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
