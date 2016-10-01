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
				input(id=key, type='text', placeholder=val)
				br
		.col-xs
			.row.middle-xs.around-xs
				each b,i in buttons
					button.button.pure-button.col-xs-5(id='button' + (i + 1)) !{b}
		.status
	p#status-text
	script(src='//cdnjs.cloudflare.com/ajax/libs/jquery/2.2.4/jquery.js')
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
.on 'connection', (socket) ->
	console.log "Connected Client: #{socket.id} auth:#{socket.auth?}"

	socket.on 'BTN_PRESSED', (data) ->
		console.log "Button Pressed: #{JSON.stringify(data, null, 2)} auth:#{socket.auth?}"
		@emit 'response', "hi #{@.client.user}.  we recd:#{data.msg}"
		# , { ctr: ctr++, user:data.username or 'unknown'}
	socket.on 'disconnect', ->
		console.log 'Disconnected Client: ' + @id

clients = require './accounts'

findclient = (uname) -> clients.find (x) -> x.username is uname

require('../') io,

	authenticate: (s, d, callback) ->

		console.log "Asking to auth: #{Object.keys d}. auth:#{s.auth?}"

		#get credentials sent by the client
		console.log """
			username: #{uname = d.username}
			password: #{pword = d.password}
		"""

		foundclient = findclient uname
		console.log "found: #{foundclient}"

		if not foundclient?
			console.log 'couldnt find user'
			callback new(Error)('User not found')
		else
			callback null, pword is foundclient.password

	, postAuthenticate: (s, d) ->
		user = findclient d.username
		console.log "authenitcated: #{user}"
		s.client.user = user

	, timeout	: 99999


# res.sendFile __dirname + '/index.html'
# app.use express.static(__dirname + '/')

# //- link(rel='stylesheet' href='//maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.css')
# //- link(rel='stylesheet' href='//cdnjs.cloudflare.com/ajax/libs/bootstrap-material-design/4.0.2/bootstrap-material-design.css')
