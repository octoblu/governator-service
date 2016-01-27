class DeployController
  constructor: ({@client,@deployDelay}) ->

  create: (request, response) =>
    deployTime = Date.now() + @deployDelay
    {name} = request.body
    metadata = JSON.stringify request.body
    @client.hset "governator:#{name}", 'request:metadata', metadata, (error) =>
      return @sendError {response, error} if error?
      @client.zadd 'governator:deploys', deployTime, "governator:#{metadata.name}", (error) =>
        return @sendError {response, error} if error?
        response.sendStatus 201

  sendError: ({response, error}) =>
    code = error.code ? 500
    return response.sendStatus code unless error.message?
    return response.status(code).send error.message

module.exports = DeployController
