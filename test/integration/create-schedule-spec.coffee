UUID          = require 'uuid'
shmock        = require 'shmock'
request       = require 'request'
redis         = require 'fakeredis'
enableDestroy = require 'server-destroy'
Server        = require '../../server'

describe 'Create Schedule', ->
  beforeEach ->
    @meshbluServer = shmock 30000
    enableDestroy @meshbluServer

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

    @logFn = sinon.spy()

    @sut = new Server {
      meshbluConfig: meshbluConfig
      client: client
      port: 20000
      disableLogging: true
      deployDelay: 1
      redisQueue: 'governator:deploys'
      requiredClusters: ['minor']
      cluster: 'super'
      deployStateUri: 'http://localhost'
      @logFn
    }
    @sut.run done

  afterEach ->
    @sut.destroy()
    @meshbluServer.destroy()

  describe 'POST /schedules', ->
    describe 'when exists', ->
      beforeEach (done) ->
        @client.set 'governator:/somedir/my-governed-deploy:octoblu/my-governed-deploy:v1', '', done

      beforeEach (done) ->
        governatorAuth = new Buffer('governator-uuid:governator-token').toString 'base64'

        @meshbluServer
          .get '/v2/whoami'
          .set 'Authorization', "Basic #{governatorAuth}"
          .reply 200, uuid: 'governator-uuid'

        options =
          uri: '/schedules'
          baseUrl: 'http://localhost:20000'
          auth: {username: 'governator-uuid', password: 'governator-token'}
          json:
            etcdDir: '/somedir/my-governed-deploy'
            dockerUrl: 'octoblu/my-governed-deploy:v1'
            deployAt: 550959

        request.post options, (error, @response, @body) =>
          return done error if error?
          done()

      it 'should return a 201', ->
        expect(@response.statusCode).to.equal 201, @body

      it 'should update the sorted set', (done) ->
        keyName = 'governator:/somedir/my-governed-deploy:octoblu/my-governed-deploy:v1'
        @client.zscore 'governator:deploys', keyName, (error, rank) =>
          return done error if error?
          expect(rank).to.equal 550959
          done()

    describe 'when does not exist', ->
      beforeEach (done) ->
        @client.del 'governator:/somedir/my-governed-deploy:octoblu/my-governed-deploy:v1', done

      beforeEach (done) ->
        governatorAuth = new Buffer('governator-uuid:governator-token').toString 'base64'

        @meshbluServer
          .get '/v2/whoami'
          .set 'Authorization', "Basic #{governatorAuth}"
          .reply 200, uuid: 'governator-uuid'

        options =
          uri: '/schedules'
          baseUrl: 'http://localhost:20000'
          auth: {username: 'governator-uuid', password: 'governator-token'}
          json:
            etcdDir: '/somedir/my-governed-deploy'
            dockerUrl: 'octoblu/my-governed-deploy:v1'
            deployAt: 550959

        request.post options, (error, @response, @body) =>
          done error

      it 'should return a 404', ->
        expect(@response.statusCode).to.equal 404, @body

    describe 'when called with invalid auth', ->
      beforeEach (done) ->
        wrongAuth = new Buffer('wrong-uuid:wrong-token').toString 'base64'

        @meshbluServer
          .get '/v2/whoami'
          .set 'Authorization', "Basic #{wrongAuth}"
          .reply 403

        options =
          uri: '/schedules'
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
          uri: '/schedules'
          baseUrl: 'http://localhost:20000'
          auth: {username: 'wrong-uuid', password: 'wrong-token'}

        request.post options, (error, response) =>
          return done error if error?
          @statusCode = response.statusCode
          done()

      it 'should return a 403', ->
        expect(@statusCode).to.equal 403
