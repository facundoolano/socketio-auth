
var _ = require('underscore');
var debug = require('debug')('socketio-auth');

function forbidConnections(nsp) {
  /*
  Set a listener so connections from unauthenticated sockets are not
  considered when emitting to the namespace. The connections will be
  restored after authentication succeeds.
  */
  nsp.on('connect', function(socket){
    if (!socket.auth) {
      debug('removing socket from %s', nsp.name);
      delete nsp.connected[socket.id];
    }
  });
}

function restoreConnection(nsp, socket) {
  /*
  If the socket attempted a connection before authentication, restore it.
  */
  if (_.findWhere(nsp.sockets, {id: socket.id})) {
    debug('restoring socket to %s', nsp.name);
    nsp.connected[socket.id] = socket;
  }
}

module.exports = function(io, config){
  /*
  Adds connection listeners to the given socket.io server, so clients
  are forced to authenticate before they can receive events.
  */

  config = config || {};
  var timeout = config.timeout || 1000;
  var postAuthenticate = config.postAuthenticate || function(){};

  _.each(io.nsps, forbidConnections);
  io.on('connection', function(socket){

    socket.auth = false;
    socket.on('authentication', function(data){

      config.authenticate(data, function(err, success){
        if (success) {
          debug('Authenticated socket %s', socket.id);
          socket.auth = true;
          _.each(io.nsps, function(nsp) {
            restoreConnection(nsp, socket);
          });
          socket.emit('authenticated', success);
          return postAuthenticate(socket, data);
        }
        socket.disconnect('unauthorized', {err: err});
      });

    });

    setTimeout(function(){
      //If the socket didn't authenticate after connection, disconnect it
      if (!socket.auth) {
        debug('Disconnecting socket %s', socket.id);
        socket.disconnect('unauthorized');
      }
    }, timeout);

  });
};
