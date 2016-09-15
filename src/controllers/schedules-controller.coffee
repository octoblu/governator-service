class SchedulesController
  constructor: ({ @deployService }) ->
    throw new Error('deployService is required') unless @deployService?

  create: (request, response) =>
    { etcdDir, dockerUrl, deployAt } = request.body

    unless etcdDir && dockerUrl
      return response.status(422).send error: "Missing etcdDir or dockerUrl, received: '#{JSON.stringify request.body}'"

    metadata = JSON.stringify request.body
    @deployService.exists { etcdDir, dockerUrl }, (error, exists) =>
      return response.sendError error if error?
      return response.sendStatus 404 unless exists
      @deployService.schedule { etcdDir, dockerUrl, deployAt, metadata }, (error) =>
        return response.sendError error if error?
        response.sendStatus 201

module.exports = SchedulesController
