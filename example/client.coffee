$ ->

	# socket.emit 'authentication', username: 'John', password: 'secret'
	url = "http://#{window.location.host}"
	console.log "url is #{url}"

	socket = io.connect  url
	window.sock = socket
	socket.on x, y for x,y of {

		connect: ->
			console.log 'connected!'
			$('.status').addClass('connected')

		authenticated: ->
			# socket.on 'connect', ->
			report 'Soy Cliente, me conecte al server. YAHOO!!!'
			# send_msg { id: 'some id', msg: 'null_msg'}
			$('.status').addClass('authenticated')
			enableUI()
		unauthorized: (err) ->
			console.log "There was an error with the authentication:", err.message
			$('.status').removeClass('authenticated authenticating')
			localStorage.removeItem 'session'

		disconnect: ->
			report 'I am the client, server is DEAD :('
			$('.status').removeClass('connected authenticated authenticating connecting')
			# $('.status').removeClass(x) for x in 'connected|authenticated|authenticating|connecting'.split '|'

		reconnect: ->
			$('.status').addClass('connecting')
			report 'Soy Cliente, me RECONECTE al server. SALVADOO!!!'

		reconnect_attemp: ->
			report 'Tried to reconnect'
			$('.status').addClass('connecting')

		reconnecting: (times) ->
			$('.status').addClass('connecting')
			report "Reconnecting.. try #:#{times}"

		response: (msg) -> report "Response: #{msg}"
	}

	enableUI = ->
		$('#msg_text').attr 'readonly', false
		$('#button1').removeClass 'pure-button-disabled'
		$('#msg_text').on 'keyup', (e) ->
			click() if e.keyCode is 13
		$('#button1').on 'click', click

	disableUI = ->
		$('#msg_text').attr readonly:true
		$('#button1').addClass 'pure-button-disabled'
		$('#msg_text').off 'keyup'
		$('#button1').off 'click'

	report = (msg) -> $('#status-text').append "<div>#{msg}</div>"
	# "#{msg} keys: #{Object.keys msg}</br>"

	click = (e) ->
		socket.emit 'BTN_PRESSED',
			id: $(@).attr 'id' or 'no id'
			msg: $('#msg_text').val() or 'null_msg'

	login = ->
		console.log socket
		# look for username in field
		if not (u = $('#user').val()).length
			# if blank, search localstorage, or use "admin"
			u = localStorage.getItem 'username' or 'admin'
			# reflect value in UI
			$('#user').val u
		localStorage.setItem 'username', u

		$('#welcome').text "login! user:#{u}"
		socket.emit 'authentication',
			username: u
			password: $('#pass').val()
			session: localStorage.getItem 'session'

	# use login button, or enter in our username and password fields to login
	$('#user, #pass').on 'keyup', (e) -> login() if e.keyCode is 13
	$('#button2').on 'click', login

	$('#button3').on 'click', -> $('#status-text').html ''
	#

	disableUI() # disable UI to start with

	# if not $('#status').hasClass 'active'
	# login('alex','vageen')
