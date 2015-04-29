# socketio-auth

This module provides hooks to implement authentication in [socket.io](https://github.com/Automattic/socket.io) without using querystrings to send credentials, which is not a good security practice.

It works by marking the clients as unauthenticated by default and listening to an `authentication` event. If a client provides wrong credentials or doesn't authenticate it gets disconnected. While the server waits for a connected client to authenticate, it won't emit any events to it.

## Usage

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
function authenticate(data, callback) {
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

* `timeout`: The amount of millisenconds to wait for a client to authenticate before disconnecting it. Defaults to 1000.

The client just needs to make sure to authenticate after connecting: 

```javascript
var socket = io.connect('http://localhost');
socket.on('connect', function(){
  socket.emit('authentication', {username: "John", password: "secret"});
});
```
The server will emit the `authenticated` event to confirm authentication.
