request = require 'request'
chai = require 'chai'
nock = require 'nock'
fs = require 'fs'
crypto = require 'crypto'
server = require '../server'
chai.should()

host = 'localhost'
port = 31000
server.start(host: host, port: port)

describe 'GET /', ->
  npmResponseHeaders =
    'cache-control': 'must-revalidate'
    'content-length': '263'
    'content-type': 'text/plain; charset=utf-8'
    'date': 'Tue, 15 Jan 2013 00:31:31 GMT'
    'server': 'CouchDB/1.2.1 (Erlang OTP/R15B)'
  npmResponseBody = fs.readFileSync(__dirname + '/mocks/root.json', 'utf8')

  beforeEach ->
    scope = nock('http://registry.npmjs.org')
      .get('/')
      .reply(200, npmResponseBody, npmResponseHeaders)

  it 'should return the unmodified body from registry.npmjs.org', (done) ->
    request "http://#{host}:#{port}/", (err, resp, body) ->
      body.should.equal npmResponseBody
      done()

  it 'should return unmodified headers registry.npmjs.org', (done) ->
    request "http://#{host}:#{port}/", (err, resp, body) ->
      resp.headers['cache-control'].should.equal npmResponseHeaders['cache-control']
      resp.headers['content-length'].should.equal npmResponseHeaders['content-length']
      resp.headers['content-type'].should.equal npmResponseHeaders['content-type']
      resp.headers['date'].should.equal npmResponseHeaders['date']
      resp.headers['server'].should.equal npmResponseHeaders['server']
      done()


describe 'GET /:moduleName', ->
  describe 'moduleName exists', ->
    npmResponseHeaders =
      'content-length': '21260'
      'content-type': 'application/json'
      'date': 'Tue, 15 Jan 2013 00:31:31 GMT'
      'etag': '"9L8SLKC29ET2GAB0QWMLENYPO"'
      'server': 'CouchDB/1.2.1 (Erlang OTP/R15B)'
      'vary': 'accept'
    npmResponseBody = fs.readFileSync(__dirname + '/mocks/coffee-script.json', 'utf8')
    expectedProxyResponseBody = npmResponseBody.replace /registry.npmjs.org/g, "#{host}:#{port}"

    beforeEach ->
      scope = nock('http://registry.npmjs.org')
        .get('/coffee-script')
        .reply(200, npmResponseBody, npmResponseHeaders)

    it 'should return the body with registry.npmjs.org substitued with proxy url', (done) ->
      request "http://#{host}:#{port}/coffee-script", (err, resp, body) ->
        body.should.equal expectedProxyResponseBody
        done()

    it 'should strip content-length header', (done) ->
      request "http://#{host}:#{port}/coffee-script", (err, resp, body) ->
        resp.headers.should.not.have.property 'content-length'
        done()

  describe 'moduleName does not exist', ->
    npmResponseHeaders =
      'cache-control': 'must-revalidate'
      'content-length': '52'
      'content-type': 'text/plain; charset=utf-8'
      'date': 'Tue, 15 Jan 2013 00:31:31 GMT'
      'server': 'CouchDB/1.2.1 (Erlang OTP/R15B)'
    npmResponseBody = fs.readFileSync(__dirname + '/mocks/document-not-found.json', 'utf8')

    beforeEach ->
      scope = nock('http://registry.npmjs.org')
        .get('/does-not-exist-asdfasdfasfd')
        .reply(404, npmResponseBody, npmResponseHeaders)

    it 'should return error document', (done) ->
      request "http://#{host}:#{port}/does-not-exist-asdfasdfasfd", (err, resp, body) ->
        resp.statusCode.should.equal 404
        body.should.equal npmResponseBody
        done()


describe 'GET /:moduleName/-/:moduleName-:version.tgz', ->
  describe 'moduleName and version exists', ->
    npmResponseHeaders =
      'Accept-Ranges': 'bytes'
      'cache-control': 'must-revalidate'
      'content-length': '131980'
      'content-md5': 'yizpsVXSpuU1Zzjh+ogwug=='
      'content-type': 'application/octet-stream'
      'date': 'Tue, 15 Jan 2013 01:53:54 GMT'
      'etag': '"yizpsVXSpuU1Zzjh+ogwug=="'
      'server': 'CouchDB/1.2.1 (Erlang OTP/R15B)'

    beforeEach ->
      scope = nock('http://registry.npmjs.org')
        .get('/jsontool/-/jsontool-1.3.0.tgz')
        .replyWithFile(200, __dirname + '/mocks/jsontool-1.3.0.tgz', npmResponseHeaders)

    it 'should return the correct file', (done) ->
      request {url: "http://#{host}:#{port}/jsontool/-/jsontool-1.3.0.tgz", encoding: null}, (err, resp, body) ->
        md5sum = crypto.createHash 'md5'
        md5sum.update body
        md5sum.digest('base64').should.equal npmResponseHeaders['content-md5']
        done()

  describe 'moduleName does not exist', ->
    npmResponseHeaders =
      'cache-control': 'must-revalidate'
      'content-length': '41'
      'content-type': 'text/plain; charset=utf-8'
      'date': 'Tue, 15 Jan 2013 00:31:31 GMT'
      'server': 'CouchDB/1.2.1 (Erlang OTP/R15B)'
    npmResponseBody = fs.readFileSync(__dirname + '/mocks/missing.json', 'utf8')

    beforeEach ->
      scope = nock('http://registry.npmjs.org')
        .get('/does-not-exist-asdfasdfasfd/-/jsontool-1.3.0.tgz')
        .reply(404, npmResponseBody, npmResponseHeaders)

    it 'should return error document', (done) ->
      request "http://#{host}:#{port}/does-not-exist-asdfasdfasfd/-/jsontool-1.3.0.tgz", (err, resp, body) ->
        resp.statusCode.should.equal 404
        body.should.equal npmResponseBody
        done()


  describe 'version does not exist', ->
    npmResponseHeaders =
      'cache-control': 'must-revalidate'
      'content-length': '64'
      'content-type': 'text/plain; charset=utf-8'
      'date': 'Tue, 15 Jan 2013 00:31:31 GMT'
      'server': 'CouchDB/1.2.1 (Erlang OTP/R15B)'
    npmResponseBody = fs.readFileSync(__dirname + '/mocks/document-missing-attachment.json', 'utf8')

    beforeEach ->
      scope = nock('http://registry.npmjs.org')
        .get('/jsontool/-/jsontool-99999.3.0.tgz')
        .reply(404, npmResponseBody, npmResponseHeaders)

    it 'should return error document', (done) ->
      request "http://#{host}:#{port}/jsontool/-/jsontool-99999.3.0.tgz", (err, resp, body) ->
        resp.statusCode.should.equal 404
        body.should.equal npmResponseBody
        done()


