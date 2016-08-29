class DeploymentsController
  constructor: ({ @deployService }) ->
    throw new Error('deployService is required') unless @deployService?

  create: (request, response) =>
    { etcdDir, dockerUrl } = request.body

    unless etcdDir && dockerUrl
      return response.status(422).send error: "Missing etcdDir or dockerUrl, received: '#{JSON.stringify request.body}'"

    metadata = JSON.stringify request.body
    @deployService.create { etcdDir, dockerUrl, metadata }, (error) =>
      return response.sendError error if error?
      response.sendStatus 201

module.exports = DeploymentsController
