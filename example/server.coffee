
[clients,path,pug,express,util,moment] =
	require x for x in ['./accounts','path','pug','express','util','moment']

debug = require('debug') path.basename(__dirname)

app = express()
# .set 'port', process.env.PORT or 3000
.use express.static __dirname + '/'
.get '/', (req, res) ->
	res.send pug.renderFile path.join(__dirname,'client.pug'),
		pretty: true
		buttons: 'message|login|clear|logout'.split '|'
		inputs: {
			msg_text: 'Message to send...'
			'user', 'pass' }

server = require('http').createServer app
# .listen app.get('port'), -> debug "Listening on port #{app.get 'port'}"

btnpressed = (data) ->
	msg = JSON.stringify data, null, 2
	debug """
		Button Pressed:#{msg} } auth:#{@auth?}
		sock: #{util.inspect @}
	"""
	if @auth
		@emit 'response', "hi #{@.client.user or 'unknown'} (#{@id}) . (#{@auth?})  we recd:#{msg} from #{@.handshake.address}"


io = require('socket.io')
.listen server
.on 'connection', (sock) ->
	address = sock.handshake.address
	debug "Connected Client: #{sock.id} auth:#{sock.auth?} ip:#{address}"
	sock.on 'disconnect', -> debug 'Disconnected Client: ' + @id
	sock.on 'BTN_PRESSED', btnpressed

findclient = (uname) -> clients.find (x) -> x.username is uname

require('../') io,

	timeout: 'none'
	authenticate: (s,d,cb) ->

		debug """
			username: #{d.username}
			password: #{d.password}
			authorized: #{s.auth?}
			ip: #{ip = s.handshake.address}
		"""
			# socket: #{util.inspect s}
		foundclient = findclient d.username
		if foundclient?
			debug "found user: #{foundclient}"
			# s.client.user = foundclient
			ok = d.password? and d.password is foundclient.password
			if !ok
				debug "using IP based auth"
				if foundclient.expires? and foundclient.ip?
					expiration = moment foundclient.expires, moment.ISO_8601
					if not (isAfter = expiration.isAfter moment())
						return cb(new Error('expiration has already occured'))
					if not (ipMatches =	ip is foundclient.ip)
						return cb(new Error('IP no matchy-matchy'))
					ok = isAfter and ipMatches

			return cb null, ok

		cb new(Error)(pword is foundclient.password and 'general error' or 'username issue')

	postAuthenticate: (s, d) ->
		debug "iam #{s.auth}"
		s.client.user = findclient d.username
		s.client.user.authorize s.handshake.address
		s.emit 'countdown', s.client.user

server.listen (port = process.env.PORT or 3000), -> debug "Listening on port #{port}"

		# else
		# if s.auth?
		# 	s.removeListener 'BTN_PRESSED'
		# 	# , { ctr: ctr++, user:data.username or 'unknown'}

		# debug "authenticated: #{user = findclient d.username}"
		# s.client.user = user




# res.sendFile __dirname + '/index.html'
# app.use express.static(__dirname + '/')

# //- link(rel='stylesheet' href='//maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.css')
# //- link(rel='stylesheet' href='//cdnjs.cloudflare.com/ajax/libs/bootstrap-material-design/4.0.2/bootstrap-material-design.css')

		# 	debug "skipping. already authed"
		# 	return cb null, s.auth

		# console.log "fuck #{require('util').inspect s}"
		# wget credentials sent by the client3
