http = require 'http'

log = (stuff) ->
  unless process.env.NODE_ENV is 'test'
    console.log stuff

# default values
host = 'localhost'
port = 3000

exports = module.exports

server = http.createServer (request, response) ->

  headers = request.headers
  request_host = headers.host
  delete headers.host

  npmRequestOptions = 
    hostname: 'registry.npmjs.org',
    port: 80,
    path: request.url,
    method: request.method,
    headers: headers

  log ''
  log "Request: #{request.method} #{request.url}"
  log headers

  npmRequest = http.request npmRequestOptions, (npmResponse) ->
    splitUrl = request.url.split '/'
    if request.method is 'GET' and splitUrl.length-1 is 1 and splitUrl[1] isnt ''
      # the npm registry hardcodes its url into the distribution locations.
      # we need to rewrite that to our proxy url in order for `npm install` to
      # download the packages through our proxy.
      delete npmResponse.headers['content-length']
      response.writeHead npmResponse.statusCode, npmResponse.headers

      chunks = []
      npmResponse.on 'data', (chunk) ->
        chunks.push chunk

      npmResponse.on 'end', ->
        unless chunks.length is 0
          try
            npmEntry = JSON.parse (chunks.join '')
            for own versionNum, info of npmEntry.versions
              newURL = npmEntry['versions'][versionNum]['dist']['tarball'].replace 'registry.npmjs.org', request_host
              npmEntry['versions'][versionNum]['dist']['tarball'] = newURL
            response.write JSON.stringify npmEntry
          catch e
            # need to fallback is there is an error parsing an object that is not json format
            # for instance favicon.ico
            response.write (chunks.join '')
          
        response.end()

    else
      response.writeHead npmResponse.statusCode, npmResponse.headers

      npmResponse.on 'data', (chunk) ->
        response.write chunk

      npmResponse.on 'end', ->
        response.end()

  request.on 'data', (chunk) ->
    npmRequest.write chunk

  request.on 'end', ->
    npmRequest.end()

  request.on 'error', ->
    response.statusCode = 500
    response.write 'Error proxying to npmjs.org.'
    response.end()


exports.start = (options = {}) ->
  if options.host?
    host = options.host

  if options.port?
    port = options.port

  server.listen port, ->
    log "Server listening on #{host}:#{port}.\n"

exports.stop = ->
  server.close ->
    log "Server stopped.\n"
    
