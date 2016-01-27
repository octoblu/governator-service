class Router
  route: (app) =>
    app.post '/deploys', (request, response) => response.sendStatus 201

module.exports = Router
