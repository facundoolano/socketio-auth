class User
	constructor: (@name, @username, @password) ->
	toString: -> "User: #{@name} Username:#{@username}"

module.exports = [
	new User('Super Admin','admin','password')
]
