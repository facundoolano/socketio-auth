# socketio-auth [![Build Status](https://secure.travis-ci.org/facundoolano/socketio-auth.png)](http://travis-ci.org/facundoolano/socketio-auth)

This module provides hooks to implement authentication in [socket.io](https://github.com/Automattic/socket.io) without using querystrings to send credentials, which is not a good security practice.

Client:
```javascript
var socket = io.connect('http://localhost');
socket.on('connect', function(){
  socket.emit('authentication', {username: "John", password: "secret"});
  socket.on('authenticated', function() {
    // use the socket as usual
  });
});
```

Server:
```javascript
var io = require('socket.io').listen(app);

require('socketio-auth')(io, {
  authenticate: function (socket, data, callback) {
    //get credentials sent by the client
    var username = data.username;
    var password = data.password;
    
    db.findUser('User', {username:username}, function(err, user) {
      
      //inform the callback of auth success/failure
      if (err || !user) return callback(new Error("User not found"));
      return callback(null, user.password == password);
    }
  }
});
```

The client should send an `authentication` event right after connecting, including whatever credentials are needed by the server to identify the user (i.e. user/password, auth token, etc.). The `authenticate` function receives those same credentials in 'data', and the actual 'socket' in case header information like the origin domain is important, and uses them to authenticate.

## Configuration

To setup authentication for the socket.io connections, just pass the server socket to socketio-auth with a configuration object:

```javascript
var io = require('socket.io').listen(app);

require('socketio-auth')(io, {
  authenticate: authenticate, 
  postAuthenticate: postAuthenticate,
  timeout: 1000
});
```

The supported parameters are:

* `authenticate`: The only required parameter. It's a function that takes the data sent by the client and calls a callback indicating if authentication was successfull:

```javascript
function authenticate(socket, data, callback) {
  var username = data.username;
  var password = data.password;
  
  db.findUser('User', {username:username}, function(err, user) {
    if (err || !user) return callback(new Error("User not found"));
    return callback(null, user.password == password);
  }
}
```
* `postAuthenticate`: a function to be called after the client is authenticated. It's useful to keep track of the user associated with a client socket:

```javascript
function postAuthenticate(socket, data) {
  var username = data.username;
  
  db.findUser('User', {username:username}, function(err, user) {
    socket.client.user = user;
  }
}
```

* `timeout`: The amount of millisenconds to wait for a client to authenticate before disconnecting it. Defaults to 1000. The value 'none' disables the timeout feature.

## Auth error messages

When client authentication fails, the server will emit an `unauthorized` event with the failure reason:

```javascript
socket.emit('authentication', {username: "John", password: "secret"});
socket.on('unauthorized', function(err){
  console.log("There was an error with the authentication:", err.message); 
});
```

The value of `err.message` depends on the outcome of the `authenticate` function used in the server: if the callback receives an error its message is used, if the success parameter is false the message is `'Authentication failure'` 

```javascript
function authenticate(socket, data, callback) {
  db.findUser('User', {username:data.username}, function(err, user) {
    if (err || !user) {
      //err.message will be "User not found"
      return callback(new Error("User not found"));
    }
	
    //if wrong password err.message will be "Authentication failure"
    return callback(null, user.password == data.password); 
  }
}
```

After receiving the `unauthorized` event, the client is disconnected.

## Implementation details

**socketio-auth** implements two-step authentication: upon connection, the server marks the clients as unauthenticated and listens to an `authentication` event. If a client provides wrong credentials or doesn't authenticate after a timeout period it gets disconnected. While the server waits for a connected client to authenticate, it won't emit any broadcast/namespace events to it. By using this approach the sensitive authentication data, such as user credentials or tokens, travel in the body of a secure request, rather than a querystring that can be logged or cached.

Note that during the window while the server waits for authentication, direct messages emitted to the socket (i.e. `socket.emit(msg)`) *will* be received by the client. To avoid those types of messages reaching unauthorized clients, the emission code should either be defined after the `authenticated` event is triggered by the server or the `socket.auth` flag should be checked to make sure the socket is authenticated.

See [this blog post](https://facundoolano.wordpress.com/2014/10/11/better-authentication-for-socket-io-no-query-strings/) for more details on this authentication method.
