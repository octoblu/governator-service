class CancellationController
  constructor: ({@client}) ->

  create: (request, response) =>
    {etcdDir, dockerUrl} = request.body
    metadataLocation = "governator:#{etcdDir}:#{dockerUrl}"
    @client.hset metadataLocation, 'cancellation', Date.now(), (error) =>
      return response.sendError error if error?
      @client.expire metadataLocation, 24*60*60, (error) =>
        return response.sendError error if error?
        response.sendStatus 201

module.exports = CancellationController
