request = require 'request'
shmock  = require 'shmock'
redis   = require 'fakeredis'
UUID    = require 'uuid'
Server  = require '../../server'

describe 'Create Cancellation', ->
  beforeEach ->
    @meshbluServer = shmock 30000

  beforeEach ->
    @redisKey = UUID.v1()
    @client = redis.createClient @redisKey

  beforeEach (done) ->
    meshbluConfig =
      server: 'localhost'
      port: '30000'
      uuid: 'governator-uuid'
      token: 'governator-token'

    client = redis.createClient @redisKey

    @sut = new Server {port: 20000, disableLogging: false, meshbluConfig, client}
    @sut.run done

  afterEach (done) ->
    @sut.stop done

  afterEach (done) ->
    @meshbluServer.close done

  describe 'POST /cancellations', ->
    describe 'when called with valid auth', ->
      describe 'when called with an existing deploy', ->
        beforeEach (done) ->
          governatorAuth = new Buffer('governator-uuid:governator-token').toString 'base64'

          @meshbluServer
            .get '/v2/whoami'
            .set 'Authorization', "Basic #{governatorAuth}"
            .reply 200, uuid: 'governator-uuid'

          options =
            uri: '/cancellations'
            baseUrl: 'http://localhost:20000'
            auth: {username: 'governator-uuid', password: 'governator-token'}
            json: {the: 'stuff i posted', applicationName: 'a-deploy', dockerUrl: 'octoblu/a-deploy:v1' }

          request.post options, (error, @response, @body) =>
            return done error if error?
            done()

        it 'should return a 201', ->
          expect(@response.statusCode).to.equal 201, @body

        it 'should set the cancellation metadata', (done) ->
          @client.hexists 'governator:a-deploy:octoblu/a-deploy:v1', 'cancellation', (error, exists) =>
            return done error if error?
            expect(exists).to.equal 1
            done()

    describe 'when called with invalid auth', ->
      beforeEach (done) ->
        wrongAuth = new Buffer('wrong-uuid:wrong-token').toString 'base64'

        @meshbluServer
          .get '/v2/whoami'
          .set 'Authorization', "Basic #{wrongAuth}"
          .reply 403

        options =
          uri: '/cancellations'
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
          uri: '/cancellations'
          baseUrl: 'http://localhost:20000'
          auth: {username: 'wrong-uuid', password: 'wrong-token'}

        request.post options, (error, response) =>
          return done error if error?
          @statusCode = response.statusCode
          done()

      it 'should return a 403', ->
        expect(@statusCode).to.equal 403
