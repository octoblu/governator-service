class CancellationController
  constructor: ({@client}) ->

  create: (request, response) =>
    {applicationName, dockerUrl} = request.body
    @client.hset "governator:#{applicationName}:#{dockerUrl}", 'cancellation', Date.now(), (error) =>
      return response.sendError error if error?
      response.sendStatus 201


module.exports = CancellationController
