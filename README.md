A simple http server that proxies connections to the npm registry.  Written in coffee-script.


# Install

    npm install -g npm-registry-proxy


# Usage
  
Using defaults (server listens on localhost:3000):

    npm-registry-proxy

Or you can optionally specify a host name and port for the listening server

    npm-registry-proxy -h example.com -p 80


# Development

## Run server

You can run the server with the npm start command:

    npm start

which is essentially the same thing as running `npm-registry-proxy` with no arguments

## Tests

You can run the test suite with:

    npm test