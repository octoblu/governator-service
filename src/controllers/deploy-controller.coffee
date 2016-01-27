class DeployController
  constructor: ({@client,@deployDelay}) ->

  create: (request, response) =>
    deployTime = Date.now() + @deployDelay
    {applicationName, dockerUrl} = request.body

    metadata = JSON.stringify request.body
    metadataLocation = "governator:#{applicationName}:#{dockerUrl}"
    @client.hset metadataLocation, 'request:metadata', metadata, (error) =>
      return response.sendError error if error?
      @client.zadd 'governator:deploys', deployTime, metadataLocation, (error) =>
        return response.sendError error if error?
        response.sendStatus 201

module.exports = DeployController
