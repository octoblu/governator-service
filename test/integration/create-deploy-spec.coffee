request = require 'request'
shmock  = require 'shmock'
Server  = require '../../server'

describe 'Create Deploy', ->
  beforeEach ->
    @meshbluServer = shmock 30000

  beforeEach (done) ->
    meshbluConfig =
      server: 'localhost'
      port: '30000'
      uuid: 'governator-uuid'
      token: 'governator-token'
    @sut = new Server {port: 20000, disableLogging: true, meshbluConfig}
    @sut.run done

  afterEach (done) ->
    @sut.stop done

  afterEach (done) ->
    @meshbluServer.close done

  describe 'POST /deploys', ->
    describe 'when called with valid auth', ->
      beforeEach (done) ->
        governatorAuth = new Buffer('governator-uuid:governator-token').toString 'base64'

        @meshbluServer
          .get '/v2/whoami'
          .set 'Authorization', "Basic #{governatorAuth}"
          .reply 200, uuid: 'governator-uuid'

        options =
          uri: '/deploys'
          baseUrl: 'http://localhost:20000'
          auth: {username: 'governator-uuid', password: 'governator-token'}

        request.post options, (error, response) =>
          return done error if error?
          @statusCode = response.statusCode
          done()

      it 'should return a 201', ->
        expect(@statusCode).to.equal 201

    describe 'when called with invalid auth', ->
      beforeEach (done) ->
        wrongAuth = new Buffer('wrong-uuid:wrong-token').toString 'base64'

        @meshbluServer
          .get '/v2/whoami'
          .set 'Authorization', "Basic #{wrongAuth}"
          .reply 403

        options =
          uri: '/deploys'
          baseUrl: 'http://localhost:20000'
          auth: {username: 'wrong-uuid', password: 'wrong-token'}

        request.post options, (error, response) =>
          return done error if error?
          @statusCode = response.statusCode
          done()

      it 'should return a 403', ->
        expect(@statusCode).to.equal 403

    describe 'when called the wrong valid auth', ->
      beforeEach (done) ->
        wrongAuth = new Buffer('wrong-uuid:wrong-token').toString 'base64'

        @meshbluServer
          .get '/v2/whoami'
          .set 'Authorization', "Basic #{wrongAuth}"
          .reply 200, uuid: 'wrong-uuid'

        options =
          uri: '/deploys'
          baseUrl: 'http://localhost:20000'
          auth: {username: 'wrong-uuid', password: 'wrong-token'}

        request.post options, (error, response) =>
          return done error if error?
          @statusCode = response.statusCode
          done()

      it 'should return a 403', ->
        expect(@statusCode).to.equal 403
