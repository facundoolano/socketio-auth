'use strict';

var assert = require('assert');
var EventEmitter = require('events').EventEmitter;
var util = require('util');

function NamespaceMock(name) {
  this.name = name;
  this.sockets = [];
  this.connected = {};
}

util.inherits(NamespaceMock, EventEmitter);

NamespaceMock.prototype.connect = function(client) {
  this.sockets.push(client);
  this.connected[client.id] = client;
  this.emit('connection', client);
};

function ServerSocketMock () {
  this.nsps = {
    '/User': new NamespaceMock('/User'),
    '/Message': new NamespaceMock('/Message')
  };
}

util.inherits(ServerSocketMock, EventEmitter);

ServerSocketMock.prototype.connect = function(nsp, client) {
  this.emit('connection', client);
  this.nsps[nsp].connect(client);
};

ServerSocketMock.prototype.emit = function(event, data, cb) {
  ServerSocketMock.super_.prototype.emit.call(this, event, data);

  //fakes client acknowledgment
  if (cb) {
    process.nextTick(cb);
  }
};

function ClientSocketMock(id) {
  this.id = id;
  this.client = {};
}
util.inherits(ClientSocketMock, EventEmitter);

ClientSocketMock.prototype.disconnect = function() {
  this.emit('disconnect');
};

function authenticate(socket, data, cb) {
  if (!data.token) {
    cb(new Error('Missing credentials'));
  }

  cb(null, data.token === 'fixedtoken');
}

describe('Server socket authentication', function() {
  var server;
  var client;

  beforeEach(function() {
    server = new ServerSocketMock();

    require('../lib/socketio-auth')(server, {
      timeout:80,
      authenticate: authenticate
    });

    client = new ClientSocketMock(5);
  });

  it('Should mark the socket as unauthenticated upon connection', function(done) {
    assert(client.auth === undefined);
    server.connect('/User', client);
    process.nextTick(function() {
      assert(client.auth === false);
      done();
    });
  });

  it('Should not send messages to unauthenticated sockets', function(done) {
    server.connect('/User', client);
    process.nextTick(function() {
      assert(!server.nsps['/User'][5]);
      done();
    });
  });

  it('Should disconnect sockets that do not authenticate', function(done) {
    server.connect('/User', client);
    client.on('disconnect', function() {
      done();
    });
  });

  it('Should authenticate with valid credentials', function(done) {
    server.connect('/User', client);
    process.nextTick(function() {
      client.on('authenticated', function() {
        assert(client.auth);
        done();
      });
      client.emit('authentication', {token: 'fixedtoken'});
    });
  });

  it('Should call post auth function', function(done) {
    server = new ServerSocketMock();
    client = new ClientSocketMock(5);

    var postAuth = function(socket, tokenData) {
      assert.equal(tokenData.token, 'fixedtoken');
      assert.equal(socket, client);
      done();
    };

    require('../lib/socketio-auth')(server, {
      timeout:80,
      authenticate: authenticate,
      postAuthenticate: postAuth
    });

    server.connect('/User', client);

    process.nextTick(function() {
      client.emit('authentication', {token: 'fixedtoken'});
    });
  });

  it('Should send updates to authenticated sockets', function(done) {
    server.connect('/User', client);

    process.nextTick(function() {
      client.on('authenticated', function() {
        assert.equal(server.nsps['/User'].connected[5], client);
        done();
      });
      client.emit('authentication', {token: 'fixedtoken'});
    });
  });

  it('Should send error event on invalid credentials', function(done) {
    server.connect('/User', client);

    process.nextTick(function() {
      client.once('unauthorized', function(err) {
        assert.equal(err.message, 'Authentication failure');
        done();
      });
      client.emit('authentication', {token: 'invalid'});
    });
  });

  it('Should send error event on missing credentials', function(done) {
    server.connect('/User', client);

    process.nextTick(function() {
      client.once('unauthorized', function(err) {
        assert.equal(err.message, 'Missing credentials');
        done();
      });
      client.emit('authentication', {});
    });
  });

  it('Should disconnect on missing credentials', function(done) {
    server.connect('/User', client);

    process.nextTick(function() {
      client.once('unauthorized', function() {
        //make sure disconnect comes after unauthorized
        client.once('disconnect', function() {
          done();
        });
      });

      client.emit('authentication', {});
    });
  });

  it('Should disconnect on invalid credentials', function(done) {
    server.connect('/User', client);

    process.nextTick(function() {
      client.once('unauthorized', function() {
        //make sure disconnect comes after unauthorized
        client.once('disconnect', function() {
          done();
        });
      });
      client.emit('authentication', {token: 'invalid'});
    });
  });

});

describe('Server socket disconnect', function() {
  var server;
  var client;

  it('Should call discon function', function(done) {
    server = new ServerSocketMock();
    client = new ClientSocketMock(5);

    var discon = function(socket) {
      assert.equal(socket, client);
      done();
    };

    require('../lib/socketio-auth')(server, {
      timeout:80,
      authenticate: authenticate,
      disconnect: discon
    });

    server.connect('/User', client);

    process.nextTick(function() {
      client.disconnect();
    });
  });

});
