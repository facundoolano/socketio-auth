html = """

	link(rel='stylesheet' href='//yui.yahooapis.com/pure/0.6.0/pure-min.css')
	link(rel='stylesheet' href='//cdnjs.cloudflare.com/ajax/libs/flexboxgrid/6.3.1/flexboxgrid.css')
	style
		:stylus
			body
				padding 20px
			.button
				border 2px black dashed
			.welcome
				padding 10px
				font-size 36pt
			.status
				background grey
				width 100px
				height 60px
			.authenticated
				background green !important
			.connected
				background red
			.authenticating
				background orange !important
			#status-text
				font-size 20pt
				background darkgrey
			input[type=text]
				width 100%

	.row.welcome hello
	.row.middle-xs
		.col-xs-6
			each val, key in inputs
				input(id=key, name=key, type='text', placeholder=val)
				br
		.col-xs
			.row.middle-xs.around-xs
				each b,i in buttons
					button.button.pure-button.col-xs-5(id='button' + (i + 1)) !{b}
		.status
	p#status-text
	script(src='//cdnjs.cloudflare.com/ajax/libs/jquery/2.2.4/jquery.js')
	script(src='//cdnjs.cloudflare.com/ajax/libs/js-cookie/latest/js.cookie.js')
	script(src='//cdnjs.cloudflare.com/ajax/libs/socket.io/1.4.8/socket.io.js')
	script(src='//rawgit.com/jashkenas/coffeescript/1.10.0/extras/coffee-script.js')
	script(src='./clientside.coffee' type='text/coffeescript')

"""
[http,pug,express] = (require x for x in ['http','pug','express'])

app = express()
.set 'port', process.env.PORT or 3000
.use express.static __dirname + '/'
.get '/', (req, res) ->
	res.send pug.render html,
		pretty: true
		buttons: ["SEND MSG","LOGIN"]
		inputs:
			msg_text: 'Message...'
			user: 'user'
			pass: 'pass'

server = http.createServer app
.listen app.get('port'), -> console.log "Listening on port #{app.get 'port'}"

ctr = 0
io = require('socket.io') server
.on 'connection', (sock) ->
	console.log "Connected Client: #{sock.id} auth:#{sock.auth?}"
	sock.on 'disconnect', ->
		console.log 'Disconnected Client: ' + @id

clients = require './accounts'

findclient = (uname) -> clients.find (x) -> x.username is uname

require('../') io,

	timeout: 'none'
	authenticate: (s,d,cb) ->
 		# wget credentials sent by the client3
		console.log """
			username: #{uname = d.username}
			password: #{pword = d.password}
			authorized: #{s.auth?}
		"""

		foundclient = findclient uname
		console.log "found: #{foundclient}"
		if foundclient?
			return cb null, pword is foundclient.password
		else
			s.removeListener 'BTN_PRESSED'
			cb new(Error)(pword is foundclient.password and 'general error' or 'username issue')


			# s.disconnect()


	postAuthenticate: (s, d) ->
		if s.auth?
			s.on 'BTN_PRESSED', (data) ->
			console.log "Button Pressed: #{JSON.stringify(data, null, 2)} auth:#{s.auth?}"
			@emit 'response', "hi #{@.client.user}. (#{s.auth?})  we recd:#{data.msg}"
		else
			s.removeListener 'BTN_PRESSED'
			# , { ctr: ctr++, user:data.username or 'unknown'}

		console.log "authenticated: #{user = findclient d.username}"
		s.client.user = user




# res.sendFile __dirname + '/index.html'
# app.use express.static(__dirname + '/')

# //- link(rel='stylesheet' href='//maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.css')
# //- link(rel='stylesheet' href='//cdnjs.cloudflare.com/ajax/libs/bootstrap-material-design/4.0.2/bootstrap-material-design.css')
