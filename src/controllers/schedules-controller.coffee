class SchedulesController
  constructor: ({@client,@redisQueue}) ->
    throw new Error('client is required') unless @client?
    throw new Error('redisQueue is required') unless @redisQueue?

  create: (request, response) =>
    {etcdDir, dockerUrl, deployAt} = request.body

    unless etcdDir && dockerUrl
      return response.status(422).send error: "Missing etcdDir or dockerUrl, received: '#{JSON.stringify request.body}'"

    metadata = JSON.stringify request.body
    metadataLocation = "governator:#{etcdDir}:#{dockerUrl}"
    @client.zadd @redisQueue, deployAt, metadataLocation, (error) =>
      return response.sendError error if error?
      response.sendStatus 201

module.exports = SchedulesController
