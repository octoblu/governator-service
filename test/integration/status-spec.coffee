request       = require 'request'
shmock        = require 'shmock'
enableDestroy = require 'server-destroy'
UUID          = require 'uuid'
RedisNs       = require '@octoblu/redis-ns'
redis         = require 'ioredis'
Server        = require '../../server'

describe 'Get Status', ->
  beforeEach ->
    @meshbluServer = shmock 30000
    enableDestroy @meshbluServer

  beforeEach (done) ->
    @redisKey = UUID.v1()
    meshbluConfig =
      server: 'localhost'
      port: '30000'
      uuid: 'governator-uuid'
      token: 'governator-token'


    @client = new RedisNs @redisKey, redis.createClient 'redis://localhost:6379', dropBufferSupport: true

    @sut = new Server {
      meshbluConfig: meshbluConfig
      port: 20000
      disableLogging: true
      deployDelay: 0
      redisUri: 'redis://localhost:6379'
      namespace: @redisKey
      maxConnections: 2,
      requiredClusters: ['minor']
      cluster: 'super'
      deployStateUri: 'http://localhost'
    }
    @sut.run done

  afterEach ->
    @sut.destroy()
    @meshbluServer.destroy()

  describe 'GET /status', ->
    describe 'when called with valid auth', ->
      describe 'when called with a pending deploy', ->
        beforeEach (done) ->
          metadata =
            etcdDir: '/foo/bar'
            dockerUrl: 'quay.io/foo/bar:v1.0.0'

          @client.hset "governator:/foo/bar:quay.io/foo/bar:v1.0.0", 'request:metadata', JSON.stringify(metadata), done

        beforeEach (done) ->
          @client.zadd "governator:deploys", 1921925912, "governator:/foo/bar:quay.io/foo/bar:v1.0.0", done

        beforeEach (done) ->
          governatorAuth = new Buffer('governator-uuid:governator-token').toString 'base64'

          @meshbluServer
            .get '/v2/whoami'
            .set 'Authorization', "Basic #{governatorAuth}"
            .reply 200, uuid: 'governator-uuid'

          options =
            uri: '/status'
            baseUrl: 'http://localhost:20000'
            auth: {username: 'governator-uuid', password: 'governator-token'}
            json: true

          request.get options, (error, @response, @body) =>
            return done error if error?
            done()

        it 'should return a 200', ->
          expect(@response.statusCode).to.equal 200, @body

        it 'should return a response', ->
          expectedResponse =
            'governator:/foo/bar:quay.io/foo/bar:v1.0.0':
              key: 'governator:/foo/bar:quay.io/foo/bar:v1.0.0'
              deployAt: 1921925912
              status: 'pending'

          expect(@response.body).to.deep.equal expectedResponse

      describe 'when called with a cancelled deploy', ->
        beforeEach (done) ->
          metadata =
            etcdDir: '/foo/bar'
            dockerUrl: 'quay.io/foo/bar:v1.0.0'

          @client.hset "governator:/foo/bar:quay.io/foo/bar:v1.0.0", 'request:metadata', JSON.stringify(metadata), done

        beforeEach (done) ->
          @client.zadd "governator:deploys", 1921925912, "governator:/foo/bar:quay.io/foo/bar:v1.0.0", done

        beforeEach (done) ->
          @client.hset "governator:/foo/bar:quay.io/foo/bar:v1.0.0", 'cancellation', Date.now(), done

        beforeEach (done) ->
          governatorAuth = new Buffer('governator-uuid:governator-token').toString 'base64'

          @meshbluServer
            .get '/v2/whoami'
            .set 'Authorization', "Basic #{governatorAuth}"
            .reply 200, uuid: 'governator-uuid'

          options =
            uri: '/status'
            baseUrl: 'http://localhost:20000'
            auth: {username: 'governator-uuid', password: 'governator-token'}
            json: true

          request.get options, (error, @response, @body) =>
            return done error if error?
            done()

        it 'should return a 200', ->
          expect(@response.statusCode).to.equal 200, @body

        it 'should return a response', ->
          expectedResponse =
            'governator:/foo/bar:quay.io/foo/bar:v1.0.0':
              key: 'governator:/foo/bar:quay.io/foo/bar:v1.0.0'
              deployAt: 1921925912
              status: 'cancelled'

          expect(@response.body).to.deep.equal expectedResponse
