_             = require 'lodash'
request       = require 'request'
shmock        = require 'shmock'
redis         = require 'fakeredis'
enableDestroy = require 'server-destroy'
UUID          = require 'uuid'
DeployService = require '../../src/services/deploy-service'
Server        = require '../../server'

describe 'Update Deploy State', ->
  describe 'when constructed with requiredClusters', ->
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
      redisQueue = 'governator:deploys'

      @sut = new Server {
        meshbluConfig: meshbluConfig
        client: client
        port: 20000
        disableLogging: true
        deployDelay: 1
        redisQueue: redisQueue
        requiredClusters: ['minor']
      }
      @deployService = new DeployService { client, redisQueue, deployDelay: 1 }
      @sut.run done

    afterEach ->
      @sut.destroy()
      @meshbluServer.destroy()

    describe 'PUT /v2/deployments', ->
      describe 'when called with non-existing deploy', ->
        describe 'when called with a passing build', ->
          beforeEach (done) ->
            governatorAuth = new Buffer('governator-uuid:governator-token').toString 'base64'

            @meshbluServer
              .get '/v2/whoami'
              .set 'Authorization', "Basic #{governatorAuth}"
              .reply 200, uuid: 'governator-uuid'

            options =
              uri: '/v2/deployments'
              baseUrl: 'http://localhost:20000'
              auth: {username: 'governator-uuid', password: 'governator-token'}
              json:
                repo: 'my-service'
                owner: 'octoblu'
                build:
                  passing: true
                  dockerUrl: 'octoblu/my-service:v1'

            request.put options, (error, @response, @body) =>
              return done error if error?
              done()

          it 'should return a 201', ->
            expect(@response.statusCode).to.equal 201, @body

          it 'should add to the sorted set', (done) ->
            start = (Date.now() / 1000) - 5
            end = start + 15
            @client.zcount 'governator:deploys', start, end, (error, count) =>
              return done error if error?
              expect(count).to.equal 1
              done()

          it 'should have set a ttl', (done) ->
            keyName = 'governator:/octoblu/my-service:octoblu/my-service:v1'
            @client.ttl keyName, (error, ttl) =>
              return done error if error?
              expect(ttl).to.be.greaterThan 0
              done()

          it 'should have metadata in the hash pointed to by the record in the sorted set', (done) ->
            keyName = 'governator:/octoblu/my-service:octoblu/my-service:v1'
            @client.hget keyName, 'request:metadata', (error, record) =>
              return done error if error?
              expect(JSON.parse record).to.deep.equal
                etcdDir: '/octoblu/my-service'
                dockerUrl: 'octoblu/my-service:v1'
              done()

        describe 'when called with a failing build', ->
          beforeEach (done) ->
            governatorAuth = new Buffer('governator-uuid:governator-token').toString 'base64'

            @meshbluServer
              .get '/v2/whoami'
              .set 'Authorization', "Basic #{governatorAuth}"
              .reply 200, uuid: 'governator-uuid'

            options =
              uri: '/v2/deployments'
              baseUrl: 'http://localhost:20000'
              auth: {username: 'governator-uuid', password: 'governator-token'}
              json:
                repo: 'my-service'
                owner: 'octoblu'
                build:
                  passing: false
                  dockerUrl: 'octoblu/my-service:v1'

            request.put options, (error, @response, @body) =>
              return done error if error?
              done()

          it 'should return a 406', ->
            expect(@response.statusCode).to.equal 406, @body

          it 'should add to the sorted set', (done) ->
            start = (Date.now() / 1000) - 5
            end = start + 15
            @client.zcount 'governator:deploys', start, end, (error, count) =>
              return done error if error?
              expect(count).to.equal 0
              done()

        describe 'when called with a deployment missing the dockerUrl', ->
          beforeEach (done) ->
            governatorAuth = new Buffer('governator-uuid:governator-token').toString 'base64'

            @meshbluServer
              .get '/v2/whoami'
              .set 'Authorization', "Basic #{governatorAuth}"
              .reply 200, uuid: 'governator-uuid'

            options =
              uri: '/v2/deployments'
              baseUrl: 'http://localhost:20000'
              auth: {username: 'governator-uuid', password: 'governator-token'}
              json:
                repo: 'my-service'
                owner: 'octoblu'
                build:
                  passing: true

            request.put options, (error, @response, @body) =>
              return done error if error?
              done()

          it 'should return a 422', ->
            expect(@response.statusCode).to.equal 422, @body

          it 'should add to the sorted set', (done) ->
            start = (Date.now() / 1000)
            end = start + 10
            @client.zcount 'governator:deploys', start, end, (error, count) =>
              return done error if error?
              expect(count).to.equal 0
              done()

        describe 'when called with missing minor cluster status', ->
          beforeEach (done) ->
            governatorAuth = new Buffer('governator-uuid:governator-token').toString 'base64'

            @meshbluServer
              .get '/v2/whoami'
              .set 'Authorization', "Basic #{governatorAuth}"
              .reply 200, uuid: 'governator-uuid'

            options =
              uri: '/v2/deployments'
              baseUrl: 'http://localhost:20000'
              auth: {username: 'governator-uuid', password: 'governator-token'}
              json:
                repo: 'my-service'
                owner: 'octoblu'
                build:
                  passing: true
                  dockerUrl: 'octoblu/my-service:v1'
                cluster: {}

            request.put options, (error, @response, @body) =>
              return done error if error?
              done()

          it 'should return a 201', ->
            expect(@response.statusCode).to.equal 201, @body

          it 'should add to the sorted set', (done) ->
            start = (Date.now() / 1000) - 5
            end = start + 15
            @client.zcount 'governator:deploys', start, end, (error, count) =>
              return done error if error?
              expect(count).to.equal 1
              done()

          it 'should have set a ttl', (done) ->
            keyName = 'governator:/octoblu/my-service:octoblu/my-service:v1'
            @client.ttl keyName, (error, ttl) =>
              return done error if error?
              expect(ttl).to.be.greaterThan 0
              done()

          it 'should have metadata in the hash pointed to by the record in the sorted set', (done) ->
            keyName = 'governator:/octoblu/my-service:octoblu/my-service:v1'
            @client.hget keyName, 'request:metadata', (error, record) =>
              return done error if error?
              expect(JSON.parse record).to.deep.equal
                etcdDir: '/octoblu/my-service'
                dockerUrl: 'octoblu/my-service:v1'
              done()

        describe 'when called with a failing cluster requirement', ->
          beforeEach (done) ->
            governatorAuth = new Buffer('governator-uuid:governator-token').toString 'base64'

            @meshbluServer
              .get '/v2/whoami'
              .set 'Authorization', "Basic #{governatorAuth}"
              .reply 200, uuid: 'governator-uuid'

            options =
              uri: '/v2/deployments'
              baseUrl: 'http://localhost:20000'
              auth: {username: 'governator-uuid', password: 'governator-token'}
              json:
                repo: 'my-service'
                owner: 'octoblu'
                build:
                  passing: true
                  dockerUrl: 'octoblu/my-service:v1'
                cluster:
                  minor:
                    passing: false

            request.put options, (error, @response, @body) =>
              return done error if error?
              done()

          it 'should return a 204', ->
            expect(@response.statusCode).to.equal 204, @body

          it 'should NOT be add to the sorted set', (done) ->
            start = (Date.now() / 1000) - 5
            end = start + 15
            @client.zcount 'governator:deploys', start, end, (error, count) =>
              return done error if error?
              expect(count).to.equal 0
              done()

          it 'should have metadata in the hash pointed to by the record in the sorted set', (done) ->
            keyName = 'governator:/octoblu/my-service:octoblu/my-service:v1'
            @client.hget keyName, 'request:metadata', (error, record) =>
              return done error if error?
              expect(record).to.not.exist
              done()

      describe 'when called with an existing deployment', ->
        beforeEach (done) ->
          @deployService.create {
            etcdDir: '/octoblu/my-service'
            dockerUrl: 'octoblu/my-service:v1'
          }, (error) =>
            done error

        describe 'when called with missing minor cluster status', ->
          beforeEach (done) ->
            governatorAuth = new Buffer('governator-uuid:governator-token').toString 'base64'

            @meshbluServer
              .get '/v2/whoami'
              .set 'Authorization', "Basic #{governatorAuth}"
              .reply 200, uuid: 'governator-uuid'

            options =
              uri: '/v2/deployments'
              baseUrl: 'http://localhost:20000'
              auth: {username: 'governator-uuid', password: 'governator-token'}
              json:
                repo: 'my-service'
                owner: 'octoblu'
                build:
                  passing: true
                  dockerUrl: 'octoblu/my-service:v1'
                cluster: {}

            request.put options, (error, @response, @body) =>
              return done error if error?
              done()

          it 'should return a 208', ->
            expect(@response.statusCode).to.equal 208, @body

          it 'should add to the sorted set', (done) ->
            start = (Date.now() / 1000) - 5
            end = start + 15
            @client.zcount 'governator:deploys', start, end, (error, count) =>
              return done error if error?
              expect(count).to.equal 1
              done()

          it 'should have set a ttl', (done) ->
            keyName = 'governator:/octoblu/my-service:octoblu/my-service:v1'
            @client.ttl keyName, (error, ttl) =>
              return done error if error?
              expect(ttl).to.be.greaterThan 0
              done()

          it 'should have metadata in the hash pointed to by the record in the sorted set', (done) ->
            keyName = 'governator:/octoblu/my-service:octoblu/my-service:v1'
            @client.hget keyName, 'request:metadata', (error, record) =>
              return done error if error?
              expect(JSON.parse record).to.deep.equal
                etcdDir: '/octoblu/my-service'
                dockerUrl: 'octoblu/my-service:v1'
              done()

        describe 'when called with a failing cluster requirement', ->
          beforeEach (done) ->
            governatorAuth = new Buffer('governator-uuid:governator-token').toString 'base64'

            @meshbluServer
              .get '/v2/whoami'
              .set 'Authorization', "Basic #{governatorAuth}"
              .reply 200, uuid: 'governator-uuid'

            options =
              uri: '/v2/deployments'
              baseUrl: 'http://localhost:20000'
              auth: {username: 'governator-uuid', password: 'governator-token'}
              json:
                repo: 'my-service'
                owner: 'octoblu'
                build:
                  passing: true
                  dockerUrl: 'octoblu/my-service:v1'
                cluster:
                  minor:
                    passing: false

            request.put options, (error, @response, @body) =>
              return done error if error?
              done()

          it 'should return a 204', ->
            expect(@response.statusCode).to.equal 204, @body

          it 'should have set a ttl', (done) ->
            keyName = 'governator:/octoblu/my-service:octoblu/my-service:v1'
            @client.ttl keyName, (error, ttl) =>
              return done error if error?
              expect(ttl).to.be.greaterThan 0
              done()

          it 'should set the cancellation metadata', (done) ->
            @client.hexists 'governator:/octoblu/my-service:octoblu/my-service:v1', 'cancellation', (error, exists) =>
              return done error if error?
              expect(exists).to.equal 1
              done()

      describe 'when called with an existing cancellation', ->
        beforeEach (done) ->
          @deployService.cancel {
            etcdDir: '/octoblu/my-service'
            dockerUrl: 'octoblu/my-service:v1'
          }, (error) =>
            done error

        describe 'when called with a passing cluster requirement', ->
          beforeEach (done) ->
            governatorAuth = new Buffer('governator-uuid:governator-token').toString 'base64'

            @meshbluServer
              .get '/v2/whoami'
              .set 'Authorization', "Basic #{governatorAuth}"
              .reply 200, uuid: 'governator-uuid'

            options =
              uri: '/v2/deployments'
              baseUrl: 'http://localhost:20000'
              auth: {username: 'governator-uuid', password: 'governator-token'}
              json:
                repo: 'my-service'
                owner: 'octoblu'
                build:
                  passing: true
                  dockerUrl: 'octoblu/my-service:v1'
                cluster:
                  minor:
                    passing: true

            request.put options, (error, @response, @body) =>
              return done error if error?
              done()

          it 'should return a 208', ->
            expect(@response.statusCode).to.equal 208, @body

          it 'should have set a ttl', (done) ->
            keyName = 'governator:/octoblu/my-service:octoblu/my-service:v1'
            @client.ttl keyName, (error, ttl) =>
              return done error if error?
              expect(ttl).to.be.greaterThan 0
              done()

          it 'should set the cancellation metadata', (done) ->
            @client.hexists 'governator:/octoblu/my-service:octoblu/my-service:v1', 'cancellation', (error, exists) =>
              return done error if error?
              expect(exists).to.equal 1
              done()

  describe 'when constructed with empty requiredClusters', ->
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
      redisQueue = 'governator:deploys'

      @sut = new Server {
        meshbluConfig: meshbluConfig
        client: client
        port: 20000
        disableLogging: true
        deployDelay: 1
        redisQueue: redisQueue
        requiredClusters: ''.split(',').map(_.trim)
      }
      @deployService = new DeployService { client, redisQueue, deployDelay: 1 }
      @sut.run done

    afterEach ->
      @sut.destroy()
      @meshbluServer.destroy()

    describe 'PUT /v2/deployments', ->
      describe 'when called with non-existing deploy', ->
        describe 'when called with a passing deployment', ->
          beforeEach (done) ->
            governatorAuth = new Buffer('governator-uuid:governator-token').toString 'base64'

            @meshbluServer
              .get '/v2/whoami'
              .set 'Authorization', "Basic #{governatorAuth}"
              .reply 200, uuid: 'governator-uuid'

            options =
              uri: '/v2/deployments'
              baseUrl: 'http://localhost:20000'
              auth: {username: 'governator-uuid', password: 'governator-token'}
              json:
                repo: 'my-service'
                owner: 'octoblu'
                build:
                  passing: true
                  dockerUrl: 'octoblu/my-service:v1'
                cluster: {}

            request.put options, (error, @response, @body) =>
              return done error if error?
              done()

          it 'should return a 201', ->
            expect(@response.statusCode).to.equal 201, @body

          it 'should add to the sorted set', (done) ->
            start = (Date.now() / 1000) - 5
            end = start + 15
            @client.zcount 'governator:deploys', start, end, (error, count) =>
              return done error if error?
              expect(count).to.equal 1
              done()

          it 'should have set a ttl', (done) ->
            keyName = 'governator:/octoblu/my-service:octoblu/my-service:v1'
            @client.ttl keyName, (error, ttl) =>
              return done error if error?
              expect(ttl).to.be.greaterThan 0
              done()

          it 'should have metadata in the hash pointed to by the record in the sorted set', (done) ->
            keyName = 'governator:/octoblu/my-service:octoblu/my-service:v1'
            @client.hget keyName, 'request:metadata', (error, record) =>
              return done error if error?
              expect(JSON.parse record).to.deep.equal
                etcdDir: '/octoblu/my-service'
                dockerUrl: 'octoblu/my-service:v1'
              done()
