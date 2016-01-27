class CancellationController
  constructor: ({@client}) ->

  create: (request, response) =>
    @client.hset 'governator:a-deploy', 'cancellation', Date.now(), (error) =>
      return response.sendError error if error?
      response.sendStatus 201


module.exports = CancellationController
