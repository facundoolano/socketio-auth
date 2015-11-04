'use strict';

var _ = require('lodash');
var debug = require('debug')('socketio-auth');

/**
 * Adds connection listeners to the given socket.io server, so clients
 * are forced to authenticate before they can receive events.
 *
 * @param {Object} io - the socket.io server socket
 *
 * @param {Object} config - configuration values
 * @param {Function} config.authenticate - indicates if authentication was successfull
 * @param {Function} config.postAuthenticate=noop -  called after the client is authenticated
 * @param {Number} [config.timeout=1000] - amount of millisenconds to wait for a client to
 * authenticate before disconnecting it. A value of 'none' means no connection timeout.
 */
module.exports = function socketIOAuth(io, config) {
  config = config || {};
  var timeout = config.timeout || 1000;
  var postAuthenticate = config.postAuthenticate || _.noop;

  _.each(io.nsps, forbidConnections);
  io.on('connection', function(socket) {

    socket.auth = false;
    socket.on('authentication', function(data) {

      config.authenticate(socket, data, function(err, success) {
        if (success) {
          debug('Authenticated socket %s', socket.id);
          socket.auth = true;

          _.each(io.nsps, function(nsp) {
            restoreConnection(nsp, socket);
          });

          socket.emit('authenticated', success);
          return postAuthenticate(socket, data);
        } else if (err) {
          debug('Authentication error socket %s: %s', socket.id, err.message);
          socket.emit('unauthorized', {message: err.message}, function() {
            socket.disconnect();
          });
        } else {
          debug('Authentication failure socket %s', socket.id);
          socket.emit('unauthorized', {message: 'Authentication failure'}, function() {
            socket.disconnect();
          });
        }

      });

    });

    if (timeout !== 'none') {
      setTimeout(function() {
          // If the socket didn't authenticate after connection, disconnect it
          if (!socket.auth) {
            debug('Disconnecting socket %s', socket.id);
            socket.disconnect('unauthorized');
          }
        }, timeout);
    }

  });
};

/**
 * Set a listener so connections from unauthenticated sockets are not
 * considered when emitting to the namespace. The connections will be
 * restored after authentication succeeds.
 */
function forbidConnections(nsp) {
  nsp.on('connect', function(socket) {
    if (!socket.auth) {
      debug('removing socket from %s', nsp.name);
      delete nsp.connected[socket.id];
    }
  });
}

/**
 * If the socket attempted a connection before authentication, restore it.
 */
function restoreConnection(nsp, socket) {
  if (_.findWhere(nsp.sockets, {id: socket.id})) {
    debug('restoring socket to %s', nsp.name);
    nsp.connected[socket.id] = socket;
  }
}
