class DeploymentsController
  constructor: ({@client,@deployDelay,@redisQueue}) ->
    throw new Error('client is required') unless @client?
    throw new Error('deployDelay is required') unless @deployDelay?
    throw new Error('redisQueue is required') unless @redisQueue?

  create: (request, response) =>
    deployTime = (Date.now() / 1000) + @deployDelay
    {etcdDir, dockerUrl} = request.body

    unless etcdDir && dockerUrl
      return response.status(422).send error: "Missing etcdDir or dockerUrl, received: '#{JSON.stringify request.body}'"

    metadata = JSON.stringify request.body
    metadataLocation = "governator:#{etcdDir}:#{dockerUrl}"
    @client.del metadataLocation, (error) =>
      return response.sendError error if error?
      @client.hset metadataLocation, 'request:metadata', metadata, (error) =>
        return response.sendError error if error?
        @client.expire metadataLocation, 24*60*60, (error) =>
          return response.sendError error if error?
          @client.zadd @redisQueue, Math.floor(deployTime), metadataLocation, (error) =>
            return response.sendError error if error?
            response.sendStatus 201

module.exports = DeploymentsController
