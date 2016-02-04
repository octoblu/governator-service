class CancellationController
  constructor: ({@client}) ->

  create: (request, response) =>
    {etcdDir, dockerUrl} = request.body
    @client.hset "governator:#{etcdDir}:#{dockerUrl}", 'cancellation', Date.now(), (error) =>
      return response.sendError error if error?
      response.sendStatus 201

module.exports = CancellationController
