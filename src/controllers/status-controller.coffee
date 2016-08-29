class StatusController
  constructor: ({ @deployService }) ->

  show: (request, response) =>
    @deployService.getStatus (error, result) =>
      return response.sendError error if error?
      response.status(200).send result

module.exports = StatusController
