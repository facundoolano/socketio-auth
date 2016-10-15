
[path,debug,http,pug,express] = (require x for x in ['path','debug','http','pug','express'])

app = express()
.set 'port', process.env.PORT or 3000
.use express.static __dirname + '/'
.get '/', (req, res) ->
	res.send pug.renderFile path.join(__dirname,'client.pug'),
		pretty: true
		buttons: ["SEND MSG","LOGIN"]
		inputs:
			msg_text: 'Message to send...'
			user: 'user'
			pass: 'pass'

server = http.createServer app
.listen app.get('port'), -> debug "Listening on port #{app.get 'port'}"

btnpressed = (data) ->
	debug "Button Pressed: #{JSON.stringify(data, null, 2)} auth:#{@auth?}"
	if @auth then @emit 'response', "hi #{@.client.user or 'unknown'} (#{@id}) . (#{@auth?})  we recd:#{data.msg}"

ctr = 0
io = require('socket.io') server
.on 'connect', (sock) ->
	debug "Connected Client: #{sock.id} auth:#{sock.auth?}"
	sock.on 'disconnect', -> debug 'Disconnected Client: ' + @id
	sock.on 'BTN_PRESSED', btnpressed

clients = require './accounts'

findclient = (uname) -> clients.find (x) -> x.username is uname


require('../') io,

	timeout: 'none'
	authenticate: (s,d,cb) ->

		# 	debug "skipping. already authed"
		# 	return cb null, s.auth

		# console.log "fuck #{require('util').inspect s}"
		# wget credentials sent by the client3
		debug """
			username: #{uname = d.username or ''}
			password: #{pword = d.password or ''}
			authorized: #{s.auth?}
		"""

		foundclient = findclient uname
		debug "found: #{foundclient}"
		if foundclient?
			okp = pword is foundclient.password
			s.client.user = foundclient
			return if okp and s.auth
			return cb null, okp

		cb new(Error)(pword is foundclient.password and 'general error' or 'username issue')

			# s.disconnect()

	postAuthenticate: (s, d) ->
		console.log "iam #{s.auth}"

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
