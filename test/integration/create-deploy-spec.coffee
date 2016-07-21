request       = require 'request'
shmock        = require 'shmock'
redis         = require 'fakeredis'
enableDestroy = require 'server-destroy'
UUID          = require 'uuid'
Server        = require '../../server'

describe 'Create Deploy', ->
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

    @sut = new Server {
      meshbluConfig: meshbluConfig
      client: client
      port: 20000
      disableLogging: true
      deployDelay: 1
      redisQueue: 'governator:deploys'
    }
    @sut.run done

  afterEach ->
    @sut.destroy()
    @meshbluServer.destroy()

  describe 'POST /deployments', ->
    describe 'when called with valid auth', ->
      beforeEach (done) ->
        governatorAuth = new Buffer('governator-uuid:governator-token').toString 'base64'

        @meshbluServer
          .get '/v2/whoami'
          .set 'Authorization', "Basic #{governatorAuth}"
          .reply 200, uuid: 'governator-uuid'

        options =
          uri: '/deployments'
          baseUrl: 'http://localhost:20000'
          auth: {username: 'governator-uuid', password: 'governator-token'}
          json:
            the: 'stuff i posted'
            etcdDir: '/somedir/my-governed-deploy'
            dockerUrl: 'octoblu/my-governed-deploy:v1'

        request.post options, (error, @response, @body) =>
          return done error if error?
          done()

      it 'should return a 201', ->
        expect(@response.statusCode).to.equal 201, @body

      it 'should add to the sorted set', (done) ->
        start = (Date.now() / 1000)
        end = start + 10
        @client.zcount 'governator:deploys', start, end, (error, count) =>
          return done error if error?
          expect(count).to.equal 1
          done()

      it 'should have set a ttl', (done) ->
        keyName = 'governator:/somedir/my-governed-deploy:octoblu/my-governed-deploy:v1'
        @client.ttl keyName, (error, ttl) =>
          return done error if error?
          expect(ttl).to.be.greaterThan 0
          done()

      it 'should have metadata in the hash pointed to by the record in the sorted set', (done) ->
        keyName = 'governator:/somedir/my-governed-deploy:octoblu/my-governed-deploy:v1'
        @client.hget keyName, 'request:metadata', (error, record) =>
          return done error if error?
          expect(JSON.parse record).to.deep.equal
            the: 'stuff i posted'
            etcdDir: '/somedir/my-governed-deploy'
            dockerUrl: 'octoblu/my-governed-deploy:v1'
          done()

    describe 'when called with invalid auth', ->
      beforeEach (done) ->
        wrongAuth = new Buffer('wrong-uuid:wrong-token').toString 'base64'

        @meshbluServer
          .get '/v2/whoami'
          .set 'Authorization', "Basic #{wrongAuth}"
          .reply 403

        options =
          uri: '/deployments'
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
          uri: '/deployments'
          baseUrl: 'http://localhost:20000'
          auth: {username: 'wrong-uuid', password: 'wrong-token'}

        request.post options, (error, response) =>
          return done error if error?
          @statusCode = response.statusCode
          done()

      it 'should return a 403', ->
        expect(@statusCode).to.equal 403
