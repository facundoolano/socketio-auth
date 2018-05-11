
$ ->

	updateUI = (x,err) ->

		statuses =
			authenticated:	['green', 	'Client authenticated to server.']
			connected: 			['orange', 	'Connected to server.']
			disconnected: 	['grey', 		'Client disconnected.']
			unauthorized: 	['red', 		"There was an error with the authentication: #{err or 'n/a'}"]

		$('#status')
		.css background:statuses[x][0] or 'magenta'
		.find '#text'
		.text x
		report statuses[x][1]

		# [remove? and 'removeClass' or 'addClass'] k

	socketize = -> io.connect "http://#{window.location.host}"
	window.socket = socketize()
	socket.on x,y for x,y of {

		connect: -> updateUI 'connected'

		authenticated: ->
			updateUI 'authenticated'
			localStorage.setItem 'username', $('#user').val()
			enableUI()

		unauthorized: (err) -> updateUI 'unauthorized'

		disconnect: -> updateUI 'disconnected'

		reconnect:            -> updateUI 'connecting' # , 'Attempting to reconnect.'
		reconnect_attempt:    -> updateUI 'connecting' # , 'Tried to reconnect..'
		reconnecting: (times) -> updateUI 'connecting' # , "Reconnecting.. try #:#{times}"

		response: (msg) -> report "Response: #{msg}"

		countdown: (user) ->
			time = moment user.expires, moment.ISO_8601
			$('#countdown').show('slow')
			$('#countdown').countdown time.toDate(), (event) ->
  			$(@).html(event.strftime '%D days %H:%M:%S')
	}

	[msgButton,msgText] = [$('#message'),$('#msg_text')]

	enableUI = ->
		msgText
		.attr readonly:false
		.on 'keyup', (e) -> send_message() if e.keyCode is 13
		msgButton
		.removeClass 'pure-button-disabled'
		.on 'click', send_message

	disableUI = ->
		msgText
		.attr readonly:true
		.off 'keyup'
		msgButton
		.addClass 'pure-button-disabled'
		.off 'click'

	report = (msg) -> $('#log').append "<div>#{msg}</div>"

	send_message = (e) ->
		socket.emit 'BTN_PRESSED',
			id: $(@).attr 'id' or 'no id'
			msg: $('#msg_text').val() or 'null_msg'

	login = ->
		console.log socket
		return if socket.auth? and socket.client.user.username is $('#user').val()
		socket.emit 'authentication',
			username: $('#user').val()
			password: $('#pass').val()

	# use login button, or enter in our username and password fields to login
	$('#user, #pass').on 'keyup', (e) -> login() if e.keyCode is 13
	$('#login').on 'click', login
	$('#clear').on 'click', -> $('#log').html ''

	disableUI() # disable UI to start with

	# look for username in field
	# if not (u = $('#user').val()).length
		# if blank, search localstorage, or use "admin"
		# reflect value in UI
	if (lastUser = localStorage.getItem('username'))?
		$('#user').val lastUser
		$('#welcome').text "Welcome back, #{lastUser}. Please login."
	else
		$('#welcome').text "Please enter credentials and login."

