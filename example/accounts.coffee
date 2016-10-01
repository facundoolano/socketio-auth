
store = require 'configstore'
pkg = require __dirname + '/../package.json'



cfg = new store  pkg.name,
	admin:
		name:'Super Admin'
		password:'password'
	user:
		name:'Regular User'
		password:''



console.log "using store name: #{cfg.all}"

class User
	constructor: (@username, info) ->
		@[key] = val for key,val of info
	toString: -> "User: #{@name} Username:#{@username}"


module.exports = (new User(key, val) for key, val of cfg.all)

