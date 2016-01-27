class DeployController
  constructor: ({@client,@deployDelay}) ->

  create: (request, response) =>
    deployTime = Date.now() + @deployDelay
    {name} = request.body
    metadata = JSON.stringify request.body
    @client.hset "governator:#{name}", 'request:metadata', metadata, (error) =>
      return response.sendError error if error?
      @client.zadd 'governator:deploys', deployTime, "governator:#{metadata.name}", (error) =>
        return response.sendError error if error?
        response.sendStatus 201

module.exports = DeployController
