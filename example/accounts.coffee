
store = require 'configstore'
moment = require 'moment'
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
	toString: -> "#{@name} (#{@username}) [#{@ip} - #{@expires}]"
	authorize: (ip) ->
		@ip = ip
		@expires = moment().add(3, 'days').toISOString()
		cfg.set @username, @
		console.log "saved user session for #{@}"


module.exports = (new User(key, val) for key, val of cfg.all)

