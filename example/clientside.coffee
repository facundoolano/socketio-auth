



$ ->

	# socket.emit 'authentication', username: 'John', password: 'secret'

	socket = io.connect 'http://localhost:3000'
	socket.on x, y for x,y of {

		connect: ->
			console.log 'connected!'
			$('.status').addClass('connected')

		authenticated: ->
			# socket.on 'connect', ->
			report 'Soy Cliente, me conecte al server. YAHOO!!!'
			# send_msg { id: 'some id', msg: 'null_msg'}
			$('.status').addClass('authenticated')

		unauthorized: (err) ->
		  console.log "There was an error with the authentication:", err.message
		  $('.status').removeClass('authenticated')

		disconnect: ->
			report 'I am the client, server is DEAD :('
			$('.status').removeClass('connected authenticated authenticating connecting')

		reconnect: ->
			$(',status').addClass('connecting')
			report 'Soy Cliente, me RECONECTE al server. SALVADOO!!!'

		reconnect_attemp: ->
			report 'Tried to reconnect'
			$('.status').addClass('connecting')

		reconnecting: (times) ->
			$('.status').addClass('connecting')
			report "Reconnecting.. try #:#{times}"

		response: (msg) -> report "Response: #{msg}"
	}

	send_msg 	= (data_obj) -> socket.emit 'BTN_PRESSED', data_obj
	report 		= (msg) -> $('#status-text').append msg + '</br>'
	# "#{msg} keys: #{Object.keys msg}</br>"

	click = (e) ->
		send_msg
			id: $(@).attr 'id' or 'no id'
			msg: $('#msg_text').val() or 'null_msg'


	# enterRun = (call) -> (e) ->
	# 	return if e.keyCode isnt 13
	# 	call()
	# makeSocket()

	login = (u,p) ->
		console.log "login!"
		socket.emit 'authentication',
			username: u or $('#user').val()
			password: p or $('#pass').val()
		# if not $('#status').hasClass 'active'


	$('#msg_text').on 'keyup', (e) ->
		return if e.keyCode isnt 13
		click()
	$('#user, #pass').on 'keyup', (e) ->
		login() if e.keyCode is 13

	$('#button1').on 'click', click
	$('#button2').on 'click', -> login('admin','password')

	# login('alex','vageen')
