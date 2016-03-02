_ = require 'lodash'
async = require 'async'

class StatusController
  constructor: ({@client, @redisQueue}) ->

  show: (req, res) =>
    @client.zrange @redisQueue, 0, -1, (error, data) =>
      return res.sendError(error) if error?
      async.map data, @_getData, (error, loadedData) =>
        return res.sendError(error) if error?

        res.status(200).send _.keyBy(loadedData, 'key')

  _getData: (key, callback) =>
    @client.zscore @redisQueue, key, (error, score) =>
      return callback error if error?

      status = 'pending'
      @client.hexists key, 'cancellation', (error, exists) =>
        status = 'cancelled' if exists

        callback null, {
          key: key
          deployAt: score
          status: status
        }


module.exports = StatusController
