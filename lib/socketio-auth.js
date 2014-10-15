
var _ = require('underscore');
var winston = require('winston');

function forbidConnections(nsp) {
  /* 
  Set a listener so connections from unauthenticated sockets are not
  considered when emitting to the namespace. The connections will be
  restored after authentication succeeds.
  */
  nsp.on('connection', function(socket){
    if (!socket.auth) {
      winston.debug("removing socket from", nsp.name);
      delete nsp.connected[socket.id];
    }
  });
}

function restoreConnection(nsp, socket) {
  /*
  If the socket attempted a connection before authentication, restore it.
  */
  if(_.findWhere(nsp.sockets, {id: socket.id})) {
    winston.debug("restoring socket to", nsp.name);
    nsp.connected[socket.id] = socket;
  }
}

module.exports = function(io, config){
  /* 
  Adds connection listeners to the given socket.io server, so clients
  are forced to authenticate before they can receive events.
  */

  var config = config || {};
  var timeout = config.timeout || 1000;
  var postAuthenticate = config.postAuthenticate || function(){};

  _.each(io.nsps, forbidConnections);
  io.on('connection', function(socket){
    
    socket.auth = false;
    socket.on('authentication', function(data){
      
      config.authenticate(data, function(err, success){
        if (success) {
          winston.debug("Authenticated socket ", socket.id);
          socket.auth = true;
          _.each(io.nsps, function(nsp) {
            restoreConnection(nsp, socket);
          });
          socket.emit('authenticated');
          return postAuthenticate(socket, data);
        }
        socket.disconnect('unauthorized', {err: err});
      });

    });

    setTimeout(function(){
      //If the socket didn't authenticate after connection, disconnect it
      if (!socket.auth) {
        winston.debug("Disconnecting socket ", socket.id);
        socket.disconnect('unauthorized');
      }
    }, timeout);

  });
}